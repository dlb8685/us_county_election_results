-- sqlite3 us_county_election_results.db
.header on
.mode column

/*
This is the file for all raw_data transformations, to make them simple and repeatable.
The scope is to create a staging layer
 - Coalescing the names and FIPS of countries which have drifted over time
 - Adding simple calculated fields to raw data files.
 - Cleaning up data and column names

This does not include the merging of any files together, joins for analytics, etc.
 - Exception, a few demographic files have the identical format across different files, no transformation required.
 - We union those together here and process as one unit.

Some naming conventions
- county_fips: Always rename other FIPS (fips, county_fips_code, etc.) to `county_fips`. Use as first columns for clarity, indexing.
- county_*: Prefix other columns like "name", etc. to specify `county_name`, etc.


Tables Created:
 - staging__county_seats
 - staging__county_election_results_by_year
 - staging__county_election_results_overall
 - staging__county_demographics_by_year
 - staging__county_demographics_overall
 - staging__county_economics_overall
 - staging__county_educational_attainment_by_year
 - staging__county_educational_attainment_overall
*/


---- County Seat 
DROP TABLE IF EXISTS staging__county_seats;
CREATE TABLE staging__county_seats AS
select distinct
    case when length(cast(county_fips_code as text)) = 4
            then '0' || cast(county_fips_code as text)
        else cast(county_fips_code as text)
    end as county_fips,
    county as county_name,
    State as state,
    seat as county_seat
from
    raw_data__hmdb__county_seats
;

-- Basic check for county_fips uniqueness (expected result, 0 rows)
select county_fips, count(*) from staging__county_seats group by 1 having count(*) > 1 order by 2 desc;


-- Clean up the 2024 raw data file for DC weirdness
DROP TABLE IF EXISTS staging__tonmcg__countypres_2024;
CREATE TABLE staging__tonmcg__countypres_2024 as
select *
from raw_data__tonmcg__countypres_2024
where state_name != 'District of Columbia'
union all
-- They just had to throw a wrinkle in here...
-- They had to do DC data by ward and not for all of DC at once.
select 331 as "index", 'District of Columbia' as state_name, 11001 as county_fips, 'DISTRICT OF COLUMBIA' as county_name,
    sum(votes_gop) as votes_gop, sum(votes_dem) as votes_dem, sum(total_votes) as total_votes, null as diff, null as per_gop,
    null as per_dem, null as per_point_diff
from raw_data__tonmcg__countypres_2024
where state_name = 'District of Columbia'
;


---- County election results for each election ----
DROP TABLE IF EXISTS staging__county_election_results_by_year;
CREATE TABLE staging__county_election_results_by_year AS
select
    c.*,
    -- The "swing" is the swing in the two-party vote, basically. + for Dems, - for Reps (no value judgments)
    -- So a county won by Dems 55-45 in one cycle, and is tied 50-50 in the next, is considered to have a negative 10-point "swing" (-0.10 in this format)
    round(
        ((c.votes_pct_democrat - lag(c.votes_pct_democrat) over (partition by c.county_fips order by c.year))
        - (c.votes_pct_republican - lag(c.votes_pct_republican) over (partition by c.county_fips order by c.year)))
        , 5
    ) as votes_pct_swing_from_prev_election
from
    (
    select
        b.*,
        -- Assume that any of Dem, Rep, or Other can finish #1 and #2 and then do the victory margin between 1 and 2
            -- In practice, only a Dem/Rep have finished 1-2 since 2000 but maybe there will be other years in the future...
            -- In case of am extremely rate literal tie down to the number of votes, the order is Dem > Rep > Oth
        case when b.votes_democrat >= b.votes_republican and b.votes_democrat >= b.votes_other then 'DEMOCRAT'
            when b.votes_republican > b.votes_democrat and b.votes_republican >= b.votes_other then 'REPUBLICAN'
            when b.votes_other > b.votes_democrat and b.votes_democrat > b.votes_republican then 'OTHER'
            end as winning_party,
        round(case when b.votes_democrat >= b.votes_republican and b.votes_republican >= b.votes_other
                then b.votes_pct_democrat - b.votes_pct_republican    -- D1 R2 O3
            when b.votes_democrat >= b.votes_other and b.votes_other > b.votes_republican
                then b.votes_pct_democrat - b.votes_pct_other         -- D1 R3 O2
            when b.votes_republican > b.votes_democrat and b.votes_democrat >= b.votes_other
                then b.votes_pct_republican - b.votes_pct_democrat    -- D2 R1 O3
            when b.votes_republican >= b.votes_other and b.votes_other > b.votes_democrat
                then b.votes_pct_republican - b.votes_pct_other       -- D3 R1 O2
            when b.votes_other > b.votes_democrat and b.votes_democrat >= b.votes_republican
                then b.votes_pct_other - b.votes_pct_democrat         -- D2 R3 O1
            when b.votes_other > b.votes_republican and b.votes_republican > b.votes_democrat
                then b.votes_pct_other - b.votes_pct_republican       -- D3 R2 O1
            end, 5) as winning_margin,
        round(case when b.votes_other > b.votes_democrat and b.votes_democrat >= b.votes_republican
                then 0.00000         -- D2 R3 O1
            when b.votes_other > b.votes_republican and b.votes_republican > b.votes_democrat
                then 0.00000       -- D3 R2 O1
            else b.votes_pct_democrat - b.votes_pct_republican
            end, 5) as winning_two_party_margin,
        -- Based on known percentages of the national vote, how much more or less did this county vote vs. the national result?
            -- A positive number means more Democrat than average, a negative means more Republican (no value judgments)
            -- This will basically be the partisan index. Average together the Dem and -Rep delta to account for strong 3rd party counties.
        round(case when b.year = 2000 then ((b.votes_pct_democrat - 0.48377) - (b.votes_pct_republican - 0.47861)) / 2
            when b.year = 2004 then ((b.votes_pct_democrat - 0.48267) - (b.votes_pct_republican - 0.50730)) / 2
            when b.year = 2008 then ((b.votes_pct_democrat - 0.52926) - (b.votes_pct_republican - 0.45653)) / 2
            when b.year = 2012 then ((b.votes_pct_democrat - 0.51064) - (b.votes_pct_republican - 0.47204)) / 2
            when b.year = 2016 then ((b.votes_pct_democrat - 0.48185) - (b.votes_pct_republican - 0.46086)) / 2
            when b.year = 2020 then ((b.votes_pct_democrat - 0.51306) - (b.votes_pct_republican - 0.46850)) / 2
            when b.year = 2024 then ((b.votes_pct_democrat - 0.48324) - (b.votes_pct_republican - 0.49796)) / 2
            end, 5) as votes_pct_partisan_index
    from
        (
        select
            case
                -- Shannon County, SD was changed to Oglala County after 2012 and the FIPS was changed from 46113 to 46102. Then back to 46113
                when a.county_fips = '46102' then '46113'
                -- The city and county of Bedford, VA merged in 2013.
                -- For 2012 and earlier there will be "duplicate" results for FIPS 51019 and 51515, then 51515 "goes away" in 2016.
                -- For consistency, all of them should have 51019 and be combined in analysis.
                when a.county_fips = '51515' then '51019'
                -- Jackson County and Kansas City, MO have a weird overlap. Most datasets consider them as a single unit but this has them separately.
                -- Updated the FIPS so that both of these are 29095 (Jackson County).
                -- Even wikipedia has all results added up under Jackson County.
                when a.county_fips in ('2938000', '36000') then '29095'
                -- Spencer County, IN seems to have a FIPS glitch in the 2024 data
                when a.county_fips = '18146' then '18147'
                -- Rhode Island did some unfortunate stuff in 2024 in this data set, i.e. 4400105140, 4400109280, etc. breakdowns
                -- instead of just 44001
                when substr(a.county_fips, 1, 5) in ('44001', '44003', '44005', '44007', '44009') then substr(a.county_fips, 1, 5)
                else a.county_fips
            end as county_fips,
            case
                -- Shannon County, SD was changed to Oglala County after 2012 and the FIPS was changed from 46113 to 46102. Then back to 46113
                when a.county_fips in ('46102', '46113') then 'OGLALA LAKOTA'
                -- The city and county of Bedford, VA merged in 2013.
                -- For 2012 and earlier there will be "duplicate" results for FIPS 51019 and 51515, then 51515 "goes away" in 2016.
                -- For consistency, all of them should have 51019 and be combined in analysis.
                when a.county_fips in ('51515', '51019') then 'BEDFORD'
                -- Jackson County and Kansas City, MO have a weird overlap. Most datasets consider them as a single unit but this has them separately.
                -- Updated the FIPS so that both of these are 29095 (Jackson County).
                -- Even wikipedia has all results added up under Jackson County.
                when a.county_fips in ('2938000', '29095', '36000') then 'JACKSON'
                -- Rhode Island did some unfortunate stuff in 2024 in this data set, i.e. 4400105140, 4400109280, etc. breakdowns
                -- instead of just 44001
                when substr(a.county_fips, 1, 5) = '44001' then 'BRISTOL'
                when substr(a.county_fips, 1, 5) = '44003' then 'KENT'
                when substr(a.county_fips, 1, 5) = '44005' then 'NEWPORT'
                when substr(a.county_fips, 1, 5) = '44007' then 'PROVIDENCE'
                when substr(a.county_fips, 1, 5) = '44009' then 'WASHINGTON'
                else a.county_name
            end as county_name,
            a.state_name,
            a.state_abbr,
            a.year,
            sum(a.votes_democrat) as votes_democrat,
            sum(a.votes_republican) as votes_republican,
            sum(a.votes_other) as votes_other,
            sum(a.votes_total) as votes_total,
            round(sum(a.votes_democrat) / nullif(cast(sum(a.votes_total) as float), 0), 5) as votes_pct_democrat,
            round(sum(a.votes_republican) / nullif(cast(sum(a.votes_total) as float), 0), 5) as votes_pct_republican,
            round(sum(a.votes_other) / nullif(cast(sum(a.votes_total) as float), 0), 5) as votes_pct_other,
            round(sum(a.votes_democrat) / nullif(cast(sum(a.votes_democrat + votes_republican) as float), 0), 5) as votes_pct_two_party_democrat,
            round(sum(a.votes_republican) / nullif(cast(sum(a.votes_democrat + a.votes_republican) as float), 0), 5) as votes_pct_two_party_republican            
        from
            (
            select
                case when
                    -- Many FIPS start out 1000 instead of 01000, and need a leading zero
                    length(replace(cast(county_fips as text), '.0', '')) = 4 then '0' else '' end
                    -- The raw data adds a .0 at the end of all FIPS by treating as a numeric, truncate that.
                    || replace(cast(county_fips as text), '.0', '') as county_fips,
                -- The default should be to take the county name as of 2020, to avoid scenarios where there are small differences.
                -- i.e. for 51690 it's called MARTINSVILLE earlier, then the data set changes it to MARTINSVILLE CITY in the 2020s.
                -- For Mickey Mouse cases like that, assume they changed it for a valid reason in 2024 and that the most recent is slightly preferable.
                coalesce(
                    (select county_name from raw_data__mit_election_labs__countypres_2000_2024 where year = 2020 and county_fips = t.county_fips),
                    (select max(county_name) from raw_data__mit_election_labs__countypres_2000_2024 where county_fips = t.county_fips)
                ) as county_name,
                state as state_name,
                state_po as state_abbr,
                year,
                -- There are just several states here with random splits that aren't MECE and are double counted or 4x counted in TX.
                -- This was a pain to figure out which states did and did not have problems in 2024, collating with third-party state vote totals.
                sum(case when party = 'DEMOCRAT' then candidatevotes
                    else 0 end) as votes_democrat,
                sum(case when party = 'REPUBLICAN' then candidatevotes
                    else 0 end) as votes_republican,
                -- "Helpfully" the data starts to include Undervotes and Overvotes for some counties in 2024,
                -- Which don't actually count in totalvotes or as a vote for anyone...
                -- Also some states have their own special format, just why.... especially in the 2024 data.
                -- EDIT: Leaving comments as a paper trail but removing a bunch of 2024-specific case logic and just pulling from a new source.
                sum(case when party not in ('DEMOCRAT', 'REPUBLICAN', 'UNDERVOTES', 'OVERVOTES') then candidatevotes
                    else 0 end) as votes_other,
                sum(case when party not in ('UNDERVOTES', 'OVERVOTES') then candidatevotes
                    else 0 end) as votes_total
            from
                (
                -- Use the MIT data set for 2000-2020
                select
                    year,
                    case state
                        when 'NEW HAMPSHIRE' then 'New Hampshire'
                        when 'NEW JERSEY' then 'New Jersey'
                        when 'NEW MEXICO' then 'New Mexico'
                        when 'NEW YORK' then 'New York'
                        when 'NORTH CAROLINA' then 'North Carolina'
                        when 'NORTH DAKOTA' then 'North Dakota'
                        when 'RHODE ISLAND' then 'Rhode Island'
                        when 'SOUTH CAROLINA' then 'South Carolina'
                        when 'SOUTH DAKOTA' then 'South Dakota'
                        when 'WEST VIRGINIA' then 'West Virginia'
                        else UPPER(SUBSTR(state, 1, 1)) || LOWER(SUBSTR(state, 2))
                    end as state
                    , state_po, county_name,
                    county_fips, candidate, party, candidatevotes, totalvotes, version, mode
                    from raw_data__mit_election_labs__countypres_2000_2024
                    -- The 2024 data has some weird edge cases and issues that were substantially messing this up.
                    -- Eventually I decided to find a second data source for 2024 only. This dataset is great for other years.
                    where
                        year != 2024
                union all
                -- Use an alternative dataset for 2024 election results.
                -- This was a late swap-in. But I checked some counties in Arizona and Arkansas that were issues in MIT
                -- This dataset had good data for those.
                -- It does need to be split into 3 queries to have one row per Democrat/Republican/Other to match the MIT format, so this gets long.
                select
                    2024 as year,
                    -- Make the state name play nice with MIT data
                    replace(t.state_name, 'Columbia', 'columbia') as state,
                    case t.state_name
                        when 'Alabama' then 'AL' when 'Alaska' then 'AK' when 'Arizona' then 'AZ' when 'Arkansas' then 'AR' when 'California' then 'CA' when 'Colorado' then 'CO' when 'Connecticut' then 'CT'
                        when 'Delaware' then 'DE' when 'District of Columbia' then 'DC' when 'Florida' then 'FL' when 'Georgia' then 'GA' when 'Hawaii' then 'HI' when 'Idaho' then 'ID' when 'Illinois' then 'IL'
                        when 'Indiana' then 'IN' when 'Iowa' then 'IA' when 'Kansas' then 'KS' when 'Kentucky' then 'KY' when 'Louisiana' then 'LA' when 'Maine' then 'ME' when 'Maryland' then 'MD'
                        when 'Massachusetts' then 'MA' when 'Michigan' then 'MI' when 'Minnesota' then 'MN' when 'Mississippi' then 'MS' when 'Missouri' then 'MO' when 'Montana' then 'MT' when 'Nebraska' then 'NE'
                        when 'Nevada' then 'NV' when 'New Hampshire' then 'NH' when 'New Jersey' then 'NJ' when 'New Mexico' then 'NM' when 'New York' then 'NY' when 'North Carolina' then 'NC' when 'North Dakota' then 'ND'
                        when 'Ohio' then 'OH' when 'Oklahoma' then 'OK' when 'Oregon' then 'OR' when 'Pennsylvania' then 'PA' when 'Rhode Island' then 'RI' when 'South Carolina' then 'SC' when 'South Dakota' then 'SD'
                        when 'Tennessee' then 'TN' when 'Texas' then 'TX' when 'Utah' then 'UT' when 'Vermont' then 'VT' when 'Virginia' then 'VA' when 'Washington' then 'WA' when 'West Virginia' then 'WV'
                        when 'Wisconsin' then 'WI' when 'Wyoming' then 'WY'
                    end as state_po,
                    -- Match MIT's format for county name
                    -- The default should be to take the county name as of 2020, to avoid scenarios where there are small differences.
                    -- i.e. for 51690 it's called MARTINSVILLE earlier, then the data set changes it to MARTINSVILLE CITY in the 2020s.
                    -- For Mickey Mouse cases like that, assume they changed it for a valid reason in 2024 and that the most recent is slightly preferable.
                    coalesce(
                        (select county_name from raw_data__mit_election_labs__countypres_2000_2024 where year = 2020 and county_fips = t.county_fips),
                        (select max(county_name) from raw_data__mit_election_labs__countypres_2000_2024 where county_fips = t.county_fips)
                    ) as county_name,
                    t.county_fips, 'Kamala Harris' as candidate,
                    'DEMOCRAT' as party, t.votes_dem as candidatevotes, t.total_votes as totalvotes, null as version, null as mode
                    from staging__tonmcg__countypres_2024 t
                union all
                select
                    2024 as year,
                    replace(t.state_name, 'Columbia', 'columbia') as state,
                    case t.state_name
                        when 'Alabama' then 'AL' when 'Alaska' then 'AK' when 'Arizona' then 'AZ' when 'Arkansas' then 'AR' when 'California' then 'CA' when 'Colorado' then 'CO' when 'Connecticut' then 'CT'
                        when 'Delaware' then 'DE' when 'District of Columbia' then 'DC' when 'Florida' then 'FL' when 'Georgia' then 'GA' when 'Hawaii' then 'HI' when 'Idaho' then 'ID' when 'Illinois' then 'IL'
                        when 'Indiana' then 'IN' when 'Iowa' then 'IA' when 'Kansas' then 'KS' when 'Kentucky' then 'KY' when 'Louisiana' then 'LA' when 'Maine' then 'ME' when 'Maryland' then 'MD'
                        when 'Massachusetts' then 'MA' when 'Michigan' then 'MI' when 'Minnesota' then 'MN' when 'Mississippi' then 'MS' when 'Missouri' then 'MO' when 'Montana' then 'MT' when 'Nebraska' then 'NE'
                        when 'Nevada' then 'NV' when 'New Hampshire' then 'NH' when 'New Jersey' then 'NJ' when 'New Mexico' then 'NM' when 'New York' then 'NY' when 'North Carolina' then 'NC' when 'North Dakota' then 'ND'
                        when 'Ohio' then 'OH' when 'Oklahoma' then 'OK' when 'Oregon' then 'OR' when 'Pennsylvania' then 'PA' when 'Rhode Island' then 'RI' when 'South Carolina' then 'SC' when 'South Dakota' then 'SD'
                        when 'Tennessee' then 'TN' when 'Texas' then 'TX' when 'Utah' then 'UT' when 'Vermont' then 'VT' when 'Virginia' then 'VA' when 'Washington' then 'WA' when 'West Virginia' then 'WV'
                        when 'Wisconsin' then 'WI' when 'Wyoming' then 'WY'
                    end as state_po,
                    coalesce(
                        (select county_name from raw_data__mit_election_labs__countypres_2000_2024 where year = 2020 and county_fips = t.county_fips),
                        (select max(county_name) from raw_data__mit_election_labs__countypres_2000_2024 where county_fips = t.county_fips)
                    ) as county_name,
                    t.county_fips, 'Donald Trump' as candidate,
                    'REPUBLICAN' as party, t.votes_gop as candidatevotes, t.total_votes as totalvotes, null as version, null as mode
                    from staging__tonmcg__countypres_2024 t
                union all
                select
                    2024 as year,
                    replace(t.state_name, 'Columbia', 'columbia') as state,
                    case t.state_name
                        when 'Alabama' then 'AL' when 'Alaska' then 'AK' when 'Arizona' then 'AZ' when 'Arkansas' then 'AR' when 'California' then 'CA' when 'Colorado' then 'CO' when 'Connecticut' then 'CT'
                        when 'Delaware' then 'DE' when 'District of Columbia' then 'DC' when 'Florida' then 'FL' when 'Georgia' then 'GA' when 'Hawaii' then 'HI' when 'Idaho' then 'ID' when 'Illinois' then 'IL'
                        when 'Indiana' then 'IN' when 'Iowa' then 'IA' when 'Kansas' then 'KS' when 'Kentucky' then 'KY' when 'Louisiana' then 'LA' when 'Maine' then 'ME' when 'Maryland' then 'MD'
                        when 'Massachusetts' then 'MA' when 'Michigan' then 'MI' when 'Minnesota' then 'MN' when 'Mississippi' then 'MS' when 'Missouri' then 'MO' when 'Montana' then 'MT' when 'Nebraska' then 'NE'
                        when 'Nevada' then 'NV' when 'New Hampshire' then 'NH' when 'New Jersey' then 'NJ' when 'New Mexico' then 'NM' when 'New York' then 'NY' when 'North Carolina' then 'NC' when 'North Dakota' then 'ND'
                        when 'Ohio' then 'OH' when 'Oklahoma' then 'OK' when 'Oregon' then 'OR' when 'Pennsylvania' then 'PA' when 'Rhode Island' then 'RI' when 'South Carolina' then 'SC' when 'South Dakota' then 'SD'
                        when 'Tennessee' then 'TN' when 'Texas' then 'TX' when 'Utah' then 'UT' when 'Vermont' then 'VT' when 'Virginia' then 'VA' when 'Washington' then 'WA' when 'West Virginia' then 'WV'
                        when 'Wisconsin' then 'WI' when 'Wyoming' then 'WY'
                    end as state_po,
                    coalesce(
                        (select county_name from raw_data__mit_election_labs__countypres_2000_2024 where year = 2020 and county_fips = t.county_fips),
                        (select max(county_name) from raw_data__mit_election_labs__countypres_2000_2024 where county_fips = t.county_fips)
                    ) as county_name,
                    t.county_fips, 'Other' as candidate,
                    'OTHER' as party, t.total_votes - t.votes_gop - t.votes_dem as candidatevotes, t.total_votes as totalvotes,
                    null as version, null as mode
                    from staging__tonmcg__countypres_2024 t
                ) t
            group by 
                1,3,4,5
            ) a
        group by
            1,2,3,4,5
        ) b
    ) c
;

-- Checks (should return 0 results)
---- Unique fips_code by year (ignoring blanks)
select county_fips, year, count(*) from staging__county_election_results_by_year
where county_fips is not null
group by 1,2 having count(*) > 1 order by 3 desc,1,2;
---- One county name per county_fips
select county_fips, count(*) from (
    select county_fips, county_name, count(*) from staging__county_election_results_by_year
    where county_fips is not null
    group by 1,2 order by 3 desc,1,2
) a group by 1 having count(*) > 1 order by 2 desc;
---- Total votes is the sum of its three subgroups
select county_fips, county_name, state_abbr, year,
    votes_democrat, votes_republican, votes_other, votes_total, (votes_democrat + votes_republican + votes_other) as real_total
from staging__county_election_results_by_year
where votes_total <> (votes_democrat + votes_republican + votes_other);
---- Total pct adds to 100%, i.e. is the total of its three subgroups
select county_fips, county_name, state_abbr, year,
    votes_pct_democrat, votes_pct_republican, votes_pct_other
from staging__county_election_results_by_year
where round((votes_pct_democrat + votes_pct_republican + votes_pct_other), 2) <> 1.00;


---- Flattened county election results table ----
-- Create a table with one row per FIPS across all years. Purpose is to make it easier to do bucketing and correlation.
DROP TABLE IF EXISTS staging__county_election_results_overall;
CREATE TABLE staging__county_election_results_overall AS
select
    county_fips,
    county_name,
    state_name,
    state_abbr,
    max(case when year = 2000 then votes_democrat end) as votes_democrat_2000,
    max(case when year = 2000 then votes_republican end) as votes_republican_2000,
    max(case when year = 2000 then votes_other end) as votes_other_2000,
    max(case when year = 2000 then votes_total end) as votes_total_2000,
    max(case when year = 2000 then votes_pct_democrat end) as votes_pct_democrat_2000,
    max(case when year = 2000 then votes_pct_republican end) as votes_pct_republican_2000,
    max(case when year = 2000 then votes_pct_other end) as votes_pct_other_2000,
    max(case when year = 2000 then votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2000,
    max(case when year = 2000 then votes_pct_two_party_republican end) as votes_pct_two_party_republican_2000,
    max(case when year = 2000 then winning_party end) as winning_party_2000,
    max(case when year = 2000 then winning_margin end) as winning_margin_2000,
    max(case when year = 2000 then winning_two_party_margin end) as winning_two_party_margin_2000,
    max(case when year = 2000 then votes_pct_swing_from_prev_election end) as votes_pct_swing_from_prev_election_2000,
    max(case when year = 2004 then votes_democrat end) as votes_democrat_2004,
    max(case when year = 2004 then votes_republican end) as votes_republican_2004,
    max(case when year = 2004 then votes_other end) as votes_other_2004,
    max(case when year = 2004 then votes_total end) as votes_total_2004,
    max(case when year = 2004 then votes_pct_democrat end) as votes_pct_democrat_2004,
    max(case when year = 2004 then votes_pct_republican end) as votes_pct_republican_2004,
    max(case when year = 2004 then votes_pct_other end) as votes_pct_other_2004,
    max(case when year = 2004 then votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2004,
    max(case when year = 2004 then votes_pct_two_party_republican end) as votes_pct_two_party_republican_2004,
    max(case when year = 2004 then winning_party end) as winning_party_2004,
    max(case when year = 2004 then winning_margin end) as winning_margin_2004,
    max(case when year = 2004 then winning_two_party_margin end) as winning_two_party_margin_2004,
    max(case when year = 2004 then votes_pct_swing_from_prev_election end) as votes_pct_swing_from_prev_election_2004,
    max(case when year = 2008 then votes_democrat end) as votes_democrat_2008,
    max(case when year = 2008 then votes_republican end) as votes_republican_2008,
    max(case when year = 2008 then votes_other end) as votes_other_2008,
    max(case when year = 2008 then votes_total end) as votes_total_2008,
    max(case when year = 2008 then votes_pct_democrat end) as votes_pct_democrat_2008,
    max(case when year = 2008 then votes_pct_republican end) as votes_pct_republican_2008,
    max(case when year = 2008 then votes_pct_other end) as votes_pct_other_2008,
    max(case when year = 2008 then votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2008,
    max(case when year = 2008 then votes_pct_two_party_republican end) as votes_pct_two_party_republican_2008,
    max(case when year = 2008 then winning_party end) as winning_party_2008,
    max(case when year = 2008 then winning_margin end) as winning_margin_2008,
    max(case when year = 2008 then winning_two_party_margin end) as winning_two_party_margin_2008,
    max(case when year = 2008 then votes_pct_swing_from_prev_election end) as votes_pct_swing_from_prev_election_2008,
    max(case when year = 2012 then votes_democrat end) as votes_democrat_2012,
    max(case when year = 2012 then votes_republican end) as votes_republican_2012,
    max(case when year = 2012 then votes_other end) as votes_other_2012,
    max(case when year = 2012 then votes_total end) as votes_total_2012,
    max(case when year = 2012 then votes_pct_democrat end) as votes_pct_democrat_2012,
    max(case when year = 2012 then votes_pct_republican end) as votes_pct_republican_2012,
    max(case when year = 2012 then votes_pct_other end) as votes_pct_other_2012,
    max(case when year = 2012 then votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2012,
    max(case when year = 2012 then votes_pct_two_party_republican end) as votes_pct_two_party_republican_2012,
    max(case when year = 2012 then winning_party end) as winning_party_2012,
    max(case when year = 2012 then winning_margin end) as winning_margin_2012,
    max(case when year = 2012 then winning_two_party_margin end) as winning_two_party_margin_2012,
    max(case when year = 2012 then votes_pct_swing_from_prev_election end) as votes_pct_swing_from_prev_election_2012,
    max(case when year = 2016 then votes_democrat end) as votes_democrat_2016,
    max(case when year = 2016 then votes_republican end) as votes_republican_2016,
    max(case when year = 2016 then votes_other end) as votes_other_2016,
    max(case when year = 2016 then votes_total end) as votes_total_2016,
    max(case when year = 2016 then votes_pct_democrat end) as votes_pct_democrat_2016,
    max(case when year = 2016 then votes_pct_republican end) as votes_pct_republican_2016,
    max(case when year = 2016 then votes_pct_other end) as votes_pct_other_2016,
    max(case when year = 2016 then votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2016,
    max(case when year = 2016 then votes_pct_two_party_republican end) as votes_pct_two_party_republican_2016,
    max(case when year = 2016 then winning_party end) as winning_party_2016,
    max(case when year = 2016 then winning_margin end) as winning_margin_2016,
    max(case when year = 2016 then winning_two_party_margin end) as winning_two_party_margin_2016,
    max(case when year = 2016 then votes_pct_swing_from_prev_election end) as votes_pct_swing_from_prev_election_2016,
    max(case when year = 2020 then votes_democrat end) as votes_democrat_2020,
    max(case when year = 2020 then votes_republican end) as votes_republican_2020,
    max(case when year = 2020 then votes_other end) as votes_other_2020,
    max(case when year = 2020 then votes_total end) as votes_total_2020,
    max(case when year = 2020 then votes_pct_democrat end) as votes_pct_democrat_2020,
    max(case when year = 2020 then votes_pct_republican end) as votes_pct_republican_2020,
    max(case when year = 2020 then votes_pct_other end) as votes_pct_other_2020,
    max(case when year = 2020 then votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2020,
    max(case when year = 2020 then votes_pct_two_party_republican end) as votes_pct_two_party_republican_2020,
    max(case when year = 2020 then winning_party end) as winning_party_2020,
    max(case when year = 2020 then winning_margin end) as winning_margin_2020,
    max(case when year = 2020 then winning_two_party_margin end) as winning_two_party_margin_2020,
    max(case when year = 2020 then votes_pct_swing_from_prev_election end) as votes_pct_swing_from_prev_election_2020,
    max(case when year = 2024 then votes_democrat end) as votes_democrat_2024,
    max(case when year = 2024 then votes_republican end) as votes_republican_2024,
    max(case when year = 2024 then votes_other end) as votes_other_2024,
    max(case when year = 2024 then votes_total end) as votes_total_2024,
    max(case when year = 2024 then votes_pct_democrat end) as votes_pct_democrat_2024,
    max(case when year = 2024 then votes_pct_republican end) as votes_pct_republican_2024,
    max(case when year = 2024 then votes_pct_other end) as votes_pct_other_2024,
    max(case when year = 2024 then votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2004,
    max(case when year = 2024 then votes_pct_two_party_republican end) as votes_pct_two_party_republican_2024,
    max(case when year = 2024 then winning_party end) as winning_party_2024,
    max(case when year = 2024 then winning_margin end) as winning_margin_2024,
    max(case when year = 2024 then winning_two_party_margin end) as winning_two_party_margin_2024,
    max(case when year = 2024 then votes_pct_swing_from_prev_election end) as votes_pct_swing_from_prev_election_2024
from
    staging__county_election_results_by_year
group by 
    1,2,3,4
;

-- Checks (should return 0 results)
---- Unique fips_code (ignoring blanks)
select county_fips, count(*) from staging__county_election_results_overall
where county_fips is not null
group by 1 having count(*) > 1 order by 2 desc,1;



----  County age and ethnicity demographics ----
-- Combine the demographic data together from these separate files. Granularity should be FIPS + Year first, to match results by year.
    -- select * from raw_data__nber__coest00intalldata limit 100;  -- 2000s
    -- select * from raw_data__us_census_bureau__cc-est2019-alldata limit 100;  -- 2010s
    -- select * from raw_data__us_census_bureau__county_demographics_2020 limit 100;  -- 2020s
DROP TABLE IF EXISTS staging__county_demographics_by_year;
CREATE TABLE staging__county_demographics_by_year AS
select
    a.*,
    round(a.population_white / cast(a.population_total as float), 5) as population_pct_white,
    round(a.population_black / cast(a.population_total as float), 5) as population_pct_black,
    round(a.population_am_ind / cast(a.population_total as float), 5) as population_pct_am_ind,
    round(a.population_asian / cast(a.population_total as float), 5) as population_pct_asian,
    round(a.population_pacific / cast(a.population_total as float), 5) as population_pct_pacific,
    round(a.population_two_races_nh / cast(a.population_total as float), 5) as population_pct_two_races_nh,
    round(a.population_hispanic / cast(a.population_total as float), 5) as population_pct_hispanic,
    round(a.population_over_18_total / cast(a.population_total as float), 5) as population_pct_over_18,
    round(a.population_under_18 / cast(a.population_total as float), 5) as population_pct_under_18,
    round(a.population_18_to_24 / cast(a.population_total as float), 5) as population_pct_18_to_24,
    round(a.population_25_to_29 / cast(a.population_total as float), 5) as population_pct_25_to_29,
    round(a.population_30_to_34 / cast(a.population_total as float), 5) as population_pct_30_to_34,
    round(a.population_35_to_39 / cast(a.population_total as float), 5) as population_pct_35_to_39,
    round(a.population_40_to_44 / cast(a.population_total as float), 5) as population_pct_40_to_44,
    round(a.population_45_to_49 / cast(a.population_total as float), 5) as population_pct_45_to_49,
    round(a.population_50_to_54 / cast(a.population_total as float), 5) as population_pct_50_to_54,
    round(a.population_55_to_59 / cast(a.population_total as float), 5) as population_pct_55_to_59,
    round(a.population_60_to_64 / cast(a.population_total as float), 5) as population_pct_60_to_64,
    round(a.population_65_to_69 / cast(a.population_total as float), 5) as population_pct_65_to_69,
    round(a.population_70_to_74 / cast(a.population_total as float), 5) as population_pct_70_to_74,
    round(a.population_75_to_79 / cast(a.population_total as float), 5) as population_pct_75_to_79,
    round(a.population_80_to_84 / cast(a.population_total as float), 5) as population_pct_80_to_84,
    round(a.population_85_and_over / cast(a.population_total as float), 5) as population_pct_85_and_over
from
    (
    select
        case
            case when length(county) = 4 then '0' || county else '' || county end
            when '46102' then '46113'
            when '51515' then '51019'
            else case when length(county) = 4 then '0' || county else '' || county end
        end as county_fips,
        case
            -- 2000 files needs fips and county name adjustments for a couple exceptions
            when county in ('46102', '46113') then 'Oglala Lakota County'
            when county = '51515' then 'Bedford County' 
            -- Aggregation will break due to small naming differences between files, if not corrected.
            when ctyname = 'DoÒa Ana County' and stname = 'New Mexico' then 'Doña Ana County'
            when ctyname = 'La Salle Parish' and stname = 'Louisiana' then 'LaSalle Parish'
            when ctyname = 'Petersburg Census Area' and stname = 'Alaska' then 'Petersburg Borough'   
            else ctyname
        end as county_name,
        stname as state_name,
        year,
        sum(case when agegrp = 99 then tot_pop else 0 end) as population_total,
        sum(case when agegrp = 99 then nhwa_male + nhwa_female else 0 end) as population_white,
        sum(case when agegrp = 99 then nhba_male + nhba_female else 0 end) as population_black,
        sum(case when agegrp = 99 then nhia_male + nhia_female else 0 end) as population_am_ind,
        sum(case when agegrp = 99 then nhaa_male + nhaa_female else 0 end) as population_asian,
        sum(case when agegrp = 99 then nhna_male + nhna_female else 0 end) as population_pacific,
        sum(case when agegrp = 99 then nhtom_male + nhtom_female else 0 end) as population_two_races_nh,
        sum(case when agegrp = 99 then h_male + h_female else 0 end) as population_hispanic,
        -- The age code unfortunately sucks a bit. 15-19 (inclusive) is in one category (4), so take 2/5 of that, plus anything 4 and higher for eligible voters total.
        sum(case when agegrp = 4 then cast(round(tot_pop * 0.4, 0) as int) when agegrp between 5 and 18 then tot_pop else 0 end) as population_over_18_total,
        sum(case when agegrp = 4 then cast(round((nhwa_male + nhwa_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhwa_male + nhwa_female else 0 end) as population_over_18_white,
        sum(case when agegrp = 4 then cast(round((nhba_male + nhba_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhba_male + nhba_female else 0 end) as population_over_18_black,
        sum(case when agegrp = 4 then cast(round((nhia_male + nhia_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhia_male + nhia_female else 0 end) as population_over_18_am_ind,
        sum(case when agegrp = 4 then cast(round((nhaa_male + nhaa_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhaa_male + nhaa_female else 0 end) as population_over_18_asian,
        sum(case when agegrp = 4 then cast(round((nhna_male + nhna_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhna_male + nhna_female else 0 end) as population_over_18_pacific,
        sum(case when agegrp = 4 then cast(round((nhtom_male + nhtom_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhtom_male + nhtom_female else 0 end) as population_over_18_two_races,
        sum(case when agegrp = 4 then cast(round((h_male + h_female) * 0.4, 0) as int) when agegrp between 5 and 18 then h_male + h_female else 0 end) as population_over_18_hispanic,
        -- Age groups (total)
            -- NOTE: The three decade files are almost identical but the 2000 file uses age group 0 to mean literal infants of 0 years old, the others use 0 as the total.
        sum(case when agegrp in (0,1,2,3) then tot_pop when agegrp = 4 then cast(round(tot_pop * 0.6, 0) as int) else 0 end) as population_under_18,
        sum(case when agegrp = 4 then cast(round(tot_pop * 0.4, 0) as int) when agegrp = 5 then tot_pop else 0 end) as population_18_to_24,
        sum(case when agegrp = 6 then tot_pop else 0 end) as population_25_to_29,
        sum(case when agegrp = 7 then tot_pop else 0 end) as population_30_to_34,
        sum(case when agegrp = 8 then tot_pop else 0 end) as population_35_to_39,
        sum(case when agegrp = 9 then tot_pop else 0 end) as population_40_to_44,
        sum(case when agegrp = 10 then tot_pop else 0 end) as population_45_to_49,
        sum(case when agegrp = 11 then tot_pop else 0 end) as population_50_to_54,
        sum(case when agegrp = 12 then tot_pop else 0 end) as population_55_to_59,
        sum(case when agegrp = 13 then tot_pop else 0 end) as population_60_to_64,
        sum(case when agegrp = 14 then tot_pop else 0 end) as population_65_to_69,
        sum(case when agegrp = 15 then tot_pop else 0 end) as population_70_to_74,
        sum(case when agegrp = 16 then tot_pop else 0 end) as population_75_to_79,
        sum(case when agegrp = 17 then tot_pop else 0 end) as population_80_to_84,
        sum(case when agegrp = 18 then tot_pop else 0 end) as population_85_and_over
    from
        raw_data__nber__coest00intalldata
    where
        -- 2000, 2004, 2008
        yearref in (2, 6, 10)
    group by 1,2,3,4
    union all 
    select
        case
            case when length(cast(state as text)) = 1 then '0' else '' end
                || cast(state as text) 
                || case when length(cast(county as text)) = 1 then '00' when length(cast(county as text)) = 2 then '0' else '' end 
                || county
            when '46102' then '46113'
            else case when length(cast(state as text)) = 1 then '0' else '' end
                || cast(state as text) 
                || case when length(cast(county as text)) = 1 then '00' when length(cast(county as text)) = 2 then '0' else '' end 
                || county
        end as county_fips,
        -- Aggregation will break due to small naming differences between files, if not corrected.
        case when ctyname = 'DoÒa Ana County' and stname = 'New Mexico' then 'Doña Ana County'
            when ctyname = 'La Salle Parish' and stname = 'Louisiana' then 'LaSalle Parish'
            when ctyname = 'Petersburg Census Area' and stname = 'Alaska' then 'Petersburg Borough'   
            else ctyname 
        end as county_name,
        stname as state_name,
        case when year = 5 then 2012 when year = 9 then 2016 when year = 12 then 2020 end as year,
        sum(case when agegrp = 0 then tot_pop else 0 end) as population_total,
        sum(case when agegrp = 0 then nhwa_male + nhwa_female else 0 end) as population_white,
        sum(case when agegrp = 0 then nhba_male + nhba_female else 0 end) as population_black,
        sum(case when agegrp = 0 then nhia_male + nhia_female else 0 end) as population_am_ind,
        sum(case when agegrp = 0 then nhaa_male + nhaa_female else 0 end) as population_asian,
        sum(case when agegrp = 0 then nhna_male + nhna_female else 0 end) as population_pacific,
        sum(case when agegrp = 0 then nhtom_male + nhtom_female else 0 end) as population_two_races_nh,
        sum(case when agegrp = 0 then h_male + h_female else 0 end) as population_hispanic,
        -- The age code unfortunately sucks a bit. 15-19 (inclusive) is in one category (4), so take 2/5 of that, plus anything 4 and higher for eligible voters total.
        sum(case when agegrp = 4 then cast(round(tot_pop * 0.4, 0) as int) when agegrp between 5 and 18 then tot_pop else 0 end) as population_over_18_total,
        sum(case when agegrp = 4 then cast(round((nhwa_male + nhwa_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhwa_male + nhwa_female else 0 end) as population_over_18_white,
        sum(case when agegrp = 4 then cast(round((nhba_male + nhba_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhba_male + nhba_female else 0 end) as population_over_18_black,
        sum(case when agegrp = 4 then cast(round((nhia_male + nhia_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhia_male + nhia_female else 0 end) as population_over_18_am_ind,
        sum(case when agegrp = 4 then cast(round((nhaa_male + nhaa_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhaa_male + nhaa_female else 0 end) as population_over_18_asian,
        sum(case when agegrp = 4 then cast(round((nhna_male + nhna_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhna_male + nhna_female else 0 end) as population_over_18_pacific,
        sum(case when agegrp = 4 then cast(round((nhtom_male + nhtom_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhtom_male + nhtom_female else 0 end) as population_over_18_two_races,
        sum(case when agegrp = 4 then cast(round((h_male + h_female) * 0.4, 0) as int) when agegrp between 5 and 18 then h_male + h_female else 0 end) as population_over_18_hispanic,
        -- Age groups (total)
        sum(case when agegrp in (1,2,3) then tot_pop when agegrp = 4 then cast(round(tot_pop * 0.6, 0) as int) else 0 end) as population_under_18,
        sum(case when agegrp = 4 then cast(round(tot_pop * 0.4, 0) as int) when agegrp = 5 then tot_pop else 0 end) as population_18_to_24,
        sum(case when agegrp = 6 then tot_pop else 0 end) as population_25_to_29,
        sum(case when agegrp = 7 then tot_pop else 0 end) as population_30_to_34,
        sum(case when agegrp = 8 then tot_pop else 0 end) as population_35_to_39,
        sum(case when agegrp = 9 then tot_pop else 0 end) as population_40_to_44,
        sum(case when agegrp = 10 then tot_pop else 0 end) as population_45_to_49,
        sum(case when agegrp = 11 then tot_pop else 0 end) as population_50_to_54,
        sum(case when agegrp = 12 then tot_pop else 0 end) as population_55_to_59,
        sum(case when agegrp = 13 then tot_pop else 0 end) as population_60_to_64,
        sum(case when agegrp = 14 then tot_pop else 0 end) as population_65_to_69,
        sum(case when agegrp = 15 then tot_pop else 0 end) as population_70_to_74,
        sum(case when agegrp = 16 then tot_pop else 0 end) as population_75_to_79,
        sum(case when agegrp = 17 then tot_pop else 0 end) as population_80_to_84,
        sum(case when agegrp = 18 then tot_pop else 0 end) as population_85_and_over
    from
        raw_data__us_census_bureau__cc_est2019_alldata
    where
        -- 2012, 2016
        year in (5, 9)
        -- Connecticut completely overhauled their counties after 2020, use their 2019 county-population as a 2020 proxy. (just.... why?)
        or (year = 12 and stname = 'Connecticut')
    group by 1,2,3,4
    union all
    -- Get a second row with CT data and label it 2024.
    select
        case
            case when length(cast(state as text)) = 1 then '0' else '' end
                || cast(state as text) 
                || case when length(cast(county as text)) = 1 then '00' when length(cast(county as text)) = 2 then '0' else '' end 
                || county
            when '46102' then '46113'
            else case when length(cast(state as text)) = 1 then '0' else '' end
                || cast(state as text) 
                || case when length(cast(county as text)) = 1 then '00' when length(cast(county as text)) = 2 then '0' else '' end 
                || county
        end as county_fips,
        -- Aggregation will break due to small naming differences between files, if not corrected.
        case when ctyname = 'DoÒa Ana County' and stname = 'New Mexico' then 'Doña Ana County'
            when ctyname = 'La Salle Parish' and stname = 'Louisiana' then 'LaSalle Parish'  
            when ctyname = 'Petersburg Census Area' and stname = 'Alaska' then 'Petersburg Borough'      
            else ctyname 
        end as county_name,
        stname as state_name,
        2024 as year,
        sum(case when agegrp = 0 then tot_pop else 0 end) as population_total,
        sum(case when agegrp = 0 then nhwa_male + nhwa_female else 0 end) as population_white,
        sum(case when agegrp = 0 then nhba_male + nhba_female else 0 end) as population_black,
        sum(case when agegrp = 0 then nhia_male + nhia_female else 0 end) as population_am_ind,
        sum(case when agegrp = 0 then nhaa_male + nhaa_female else 0 end) as population_asian,
        sum(case when agegrp = 0 then nhna_male + nhna_female else 0 end) as population_pacific,
        sum(case when agegrp = 0 then nhtom_male + nhtom_female else 0 end) as population_two_races_nh,
        sum(case when agegrp = 0 then h_male + h_female else 0 end) as population_hispanic,
        -- The age code unfortunately sucks a bit. 15-19 (inclusive) is in one category (4), so take 2/5 of that, plus anything 4 and higher for eligible voters total.
        sum(case when agegrp = 4 then cast(round(tot_pop * 0.4, 0) as int) when agegrp between 5 and 18 then tot_pop else 0 end) as population_over_18_total,
        sum(case when agegrp = 4 then cast(round((nhwa_male + nhwa_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhwa_male + nhwa_female else 0 end) as population_over_18_white,
        sum(case when agegrp = 4 then cast(round((nhba_male + nhba_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhba_male + nhba_female else 0 end) as population_over_18_black,
        sum(case when agegrp = 4 then cast(round((nhia_male + nhia_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhia_male + nhia_female else 0 end) as population_over_18_am_ind,
        sum(case when agegrp = 4 then cast(round((nhaa_male + nhaa_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhaa_male + nhaa_female else 0 end) as population_over_18_asian,
        sum(case when agegrp = 4 then cast(round((nhna_male + nhna_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhna_male + nhna_female else 0 end) as population_over_18_pacific,
        sum(case when agegrp = 4 then cast(round((nhtom_male + nhtom_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhtom_male + nhtom_female else 0 end) as population_over_18_two_races,
        sum(case when agegrp = 4 then cast(round((h_male + h_female) * 0.4, 0) as int) when agegrp between 5 and 18 then h_male + h_female else 0 end) as population_over_18_hispanic,
        -- Age groups (total)
        sum(case when agegrp in (1,2,3) then tot_pop when agegrp = 4 then cast(round(tot_pop * 0.6, 0) as int) else 0 end) as population_under_18,
        sum(case when agegrp = 4 then cast(round(tot_pop * 0.4, 0) as int) when agegrp = 5 then tot_pop else 0 end) as population_18_to_24,
        sum(case when agegrp = 6 then tot_pop else 0 end) as population_25_to_29,
        sum(case when agegrp = 7 then tot_pop else 0 end) as population_30_to_34,
        sum(case when agegrp = 8 then tot_pop else 0 end) as population_35_to_39,
        sum(case when agegrp = 9 then tot_pop else 0 end) as population_40_to_44,
        sum(case when agegrp = 10 then tot_pop else 0 end) as population_45_to_49,
        sum(case when agegrp = 11 then tot_pop else 0 end) as population_50_to_54,
        sum(case when agegrp = 12 then tot_pop else 0 end) as population_55_to_59,
        sum(case when agegrp = 13 then tot_pop else 0 end) as population_60_to_64,
        sum(case when agegrp = 14 then tot_pop else 0 end) as population_65_to_69,
        sum(case when agegrp = 15 then tot_pop else 0 end) as population_70_to_74,
        sum(case when agegrp = 16 then tot_pop else 0 end) as population_75_to_79,
        sum(case when agegrp = 17 then tot_pop else 0 end) as population_80_to_84,
        sum(case when agegrp = 18 then tot_pop else 0 end) as population_85_and_over
    from
        raw_data__us_census_bureau__cc_est2019_alldata
    where
        -- Connecticut completely overhauled their counties after 2020, use their 2019 county-population as a 2020 proxy. (just.... why?)
        (year = 12 and stname = 'Connecticut')
    group by 1,2,3,4
    union all
    select
        case
            -- In the 2024 dataset, Rhode Island needs a lot of massaging b/c they include a bunch of granular units instead of the country itself.
            -- i.e instead of '44009', there is '4400914500', '4400925300', '4400935380', ...
            substr(case when length(cast(state as text)) = 1 then '0' else '' end
                || cast(state as text) 
                || case when length(cast(county as text)) = 1 then '00' when length(cast(county as text)) = 2 then '0' else '' end 
                || county, 1, 5)
            when '44009' then '44009'
            when '44007' then '44007'
            when '44005' then '44005'
            when '44003' then '44003'
            when '44001' then '44001'
            -- Oglala Lakota County in SD
            when '46102' then '46113'
            else case when length(cast(state as text)) = 1 then '0' else '' end
                || cast(state as text) 
                || case when length(cast(county as text)) = 1 then '00' when length(cast(county as text)) = 2 then '0' else '' end 
                || county
        end as county_fips,
        -- Aggregation will break due to small naming differences between files, if not corrected.
        case when ctyname = 'DoÒa Ana County' and stname = 'New Mexico' then 'Doña Ana County'
            when ctyname = 'La Salle Parish' and stname = 'Louisiana' then 'LaSalle Parish'
            when ctyname = 'Petersburg Census Area' and stname = 'Alaska' then 'Petersburg Borough'
            else ctyname 
        end as county_name,
        stname as state_name,
        case when year = 2 then 2020
            when year = 6 then 2024
        end as year,
        sum(case when agegrp = 0 then tot_pop else 0 end) as population_total,
        sum(case when agegrp = 0 then nhwa_male + nhwa_female else 0 end) as population_white,
        sum(case when agegrp = 0 then nhba_male + nhba_female else 0 end) as population_black,
        sum(case when agegrp = 0 then nhia_male + nhia_female else 0 end) as population_am_ind,
        sum(case when agegrp = 0 then nhaa_male + nhaa_female else 0 end) as population_asian,
        sum(case when agegrp = 0 then nhna_male + nhna_female else 0 end) as population_pacific,
        sum(case when agegrp = 0 then nhtom_male + nhtom_female else 0 end) as population_two_races_nh,
        sum(case when agegrp = 0 then h_male + h_female else 0 end) as population_hispanic,
        -- The age code unfortunately sucks a bit. 15-19 (inclusive) is in one category (4), so take 2/5 of that, plus anything 4 and higher for eligible voters total.
        sum(case when agegrp = 4 then cast(round(tot_pop * 0.4, 0) as int) when agegrp between 5 and 18 then tot_pop else 0 end) as population_over_18_total,
        sum(case when agegrp = 4 then cast(round((nhwa_male + nhwa_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhwa_male + nhwa_female else 0 end) as population_over_18_white,
        sum(case when agegrp = 4 then cast(round((nhba_male + nhba_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhba_male + nhba_female else 0 end) as population_over_18_black,
        sum(case when agegrp = 4 then cast(round((nhia_male + nhia_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhia_male + nhia_female else 0 end) as population_over_18_am_ind,
        sum(case when agegrp = 4 then cast(round((nhaa_male + nhaa_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhaa_male + nhaa_female else 0 end) as population_over_18_asian,
        sum(case when agegrp = 4 then cast(round((nhna_male + nhna_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhna_male + nhna_female else 0 end) as population_over_18_pacific,
        sum(case when agegrp = 4 then cast(round((nhtom_male + nhtom_female) * 0.4, 0) as int) when agegrp between 5 and 18 then nhtom_male + nhtom_female else 0 end) as population_over_18_two_races,
        sum(case when agegrp = 4 then cast(round((h_male + h_female) * 0.4, 0) as int) when agegrp between 5 and 18 then h_male + h_female else 0 end) as population_over_18_hispanic,
        -- Age groups (total)
        sum(case when agegrp in (1,2,3) then tot_pop when agegrp = 4 then cast(round(tot_pop * 0.6, 0) as int) else 0 end) as population_under_18,
        sum(case when agegrp = 4 then cast(round(tot_pop * 0.4, 0) as int) when agegrp = 5 then tot_pop else 0 end) as population_18_to_24,
        sum(case when agegrp = 6 then tot_pop else 0 end) as population_25_to_29,
        sum(case when agegrp = 7 then tot_pop else 0 end) as population_30_to_34,
        sum(case when agegrp = 8 then tot_pop else 0 end) as population_35_to_39,
        sum(case when agegrp = 9 then tot_pop else 0 end) as population_40_to_44,
        sum(case when agegrp = 10 then tot_pop else 0 end) as population_45_to_49,
        sum(case when agegrp = 11 then tot_pop else 0 end) as population_50_to_54,
        sum(case when agegrp = 12 then tot_pop else 0 end) as population_55_to_59,
        sum(case when agegrp = 13 then tot_pop else 0 end) as population_60_to_64,
        sum(case when agegrp = 14 then tot_pop else 0 end) as population_65_to_69,
        sum(case when agegrp = 15 then tot_pop else 0 end) as population_70_to_74,
        sum(case when agegrp = 16 then tot_pop else 0 end) as population_75_to_79,
        sum(case when agegrp = 17 then tot_pop else 0 end) as population_80_to_84,
        sum(case when agegrp = 18 then tot_pop else 0 end) as population_85_and_over
    from
        raw_data__us_census_bureau__county_demographics_2020
    where
        -- 2020
        -- Connecticut was nice enough to do a complete overhaul of their counties starting in 2021, so we'll use 2019 population data for them in the previous.
        year in (2, 6) and stname != 'Connecticut'
    group by 1,2,3,4
    ) a
;

-- Checks (should return 0 results)
---- Unique fips_code by year (ignoring blanks)
select county_fips, year, count(*) from staging__county_demographics_by_year
where county_fips is not null
group by 1,2 having count(*) > 1 order by 3 desc, 1, 2;
---- Each county_fips has 7 data points (2000, 2004, ...., 2024)
select county_fips, count(*) from staging__county_demographics_by_year
where county_fips is not null
    -- Exception, a few census areas in Alaska that were created or ended in this time period
    and county_fips not in ('02063', '02066', '02158', '02261', '02270')
group by 1 having count(*) <> 7 order by 2 desc, 1;


---- County age and demographics, flattened ----
-- Create flattened table with one row per FIPS across all years.
    -- Include subset of columns / years to have some change over time without an obscene number of columns
DROP TABLE IF EXISTS staging__county_demographics_overall;
CREATE TABLE staging__county_demographics_overall AS
select
    county_fips,
    county_name,
    state_name,
    max(case when year = 2000 then population_total else 0 end) as population_total_2000,
    max(case when year = 2004 then population_total else 0 end) as population_total_2004,
    max(case when year = 2008 then population_total else 0 end) as population_total_2008,
    max(case when year = 2012 then population_total else 0 end) as population_total_2012,
    max(case when year = 2016 then population_total else 0 end) as population_total_2016,
    max(case when year = 2020 then population_total else 0 end) as population_total_2020,
    max(case when year = 2000 then population_pct_white else 0 end) as population_pct_white_2000,
    max(case when year = 2000 then population_pct_black else 0 end) as population_pct_black_2000,
    max(case when year = 2000 then population_pct_am_ind else 0 end) as population_pct_am_ind_2000,
    max(case when year = 2000 then population_pct_asian else 0 end) as population_pct_asian_2000,
    max(case when year = 2000 then population_pct_pacific else 0 end) as population_pct_pacific_2000,
    max(case when year = 2000 then population_pct_two_races_nh else 0 end) as population_pct_two_races_nh_2000,
    max(case when year = 2000 then population_pct_hispanic else 0 end) as population_pct_hispanic_2000,
    max(case when year = 2000 then population_pct_over_18 else 0 end) as population_pct_over_18_2000,
    max(case when year = 2000 then population_pct_under_18 else 0 end) as population_pct_under_18_2000,
    max(case when year = 2000 then population_pct_18_to_24 else 0 end) as population_pct_18_to_24_2000,
    max(case when year = 2020 then population_pct_white else 0 end) as population_pct_white_2020,
    max(case when year = 2020 then population_pct_black else 0 end) as population_pct_black_2020,
    max(case when year = 2020 then population_pct_am_ind else 0 end) as population_pct_am_ind_2020,
    max(case when year = 2020 then population_pct_asian else 0 end) as population_pct_asian_2020,
    max(case when year = 2020 then population_pct_pacific else 0 end) as population_pct_pacific_2020,
    max(case when year = 2020 then population_pct_two_races_nh else 0 end) as population_pct_two_races_nh_2020,
    max(case when year = 2020 then population_pct_hispanic else 0 end) as population_pct_hispanic_2020,
    max(case when year = 2020 then population_pct_over_18 else 0 end) as population_pct_over_18_2020,
    max(case when year = 2020 then population_pct_under_18 else 0 end) as population_pct_under_18_2020,
    max(case when year = 2020 then population_pct_18_to_24 else 0 end) as population_pct_18_to_24_2020,
    -- Deltas between 2000 and 2020
    max(case when year = 2020 then population_pct_white else 0 end) - max(case when year = 2000 then population_pct_white else 0 end)
        as population_pct_white_change_2000_to_2020,
    max(case when year = 2020 then population_pct_black else 0 end) - max(case when year = 2000 then population_pct_black else 0 end)
        as population_pct_white_change_2000_to_2020,
    max(case when year = 2020 then population_pct_am_ind else 0 end) - max(case when year = 2000 then population_pct_am_ind else 0 end)
        as population_pct_white_change_2000_to_2020,
    max(case when year = 2020 then population_pct_asian else 0 end) - max(case when year = 2000 then population_pct_asian else 0 end)
        as population_pct_white_change_2000_to_2020,
    max(case when year = 2020 then population_pct_pacific else 0 end) - max(case when year = 2000 then population_pct_pacific else 0 end)
        as population_pct_white_change_2000_to_2020,
    max(case when year = 2020 then population_pct_two_races_nh else 0 end) - max(case when year = 2000 then population_pct_two_races_nh else 0 end)
        as population_pct_white_change_2000_to_2020,
    max(case when year = 2020 then population_pct_hispanic else 0 end) - max(case when year = 2000 then population_pct_hispanic else 0 end)
        as population_pct_white_change_2000_to_2020
from
    staging__county_demographics_by_year
group by 1,2,3
;

-- Checks (should return 0 results)
-- Unique FIPS
select county_fips, count(*) from staging__county_demographics_overall
where county_fips is not null
group by 1 having count(*) > 1 order by 2 desc, 1;

-- No county has over 3x the population in any year, as in 2000
-- Conversely, no county has over 3x the population in 2000 as in any other year
-- Pinal County, AZ is the fastest-growing county, went from 179,727 to 425,264 from 2000-20, that is the baseline.
select * from staging__county_demographics_overall
where population_total_2020 / population_total_2000 > 3
    or population_total_2016 / population_total_2000 > 3
    or population_total_2012 / population_total_2000 > 3
    or population_total_2008 / population_total_2000 > 3
    or population_total_2004 / population_total_2000 > 3
    or population_total_2000 / population_total_2020 > 3
    or population_total_2000 / population_total_2016 > 3
    or population_total_2000 / population_total_2012 > 3
    or population_total_2000 / population_total_2008 > 3
    or population_total_2000 / population_total_2004 > 3
;

-- Check that ethnic groups are MECE
select * from staging__county_demographics_overall 
where
    -- 2000 subgroups should add up to 100% (or 0% for a few census areas in Alaska that drop on and off)
   round((population_pct_white_2000 + population_pct_black_2000 + population_pct_am_ind_2000 + population_pct_asian_2000
        + population_pct_pacific_2000 + population_pct_two_races_nh_2000 + population_pct_hispanic_2000),
        3) not in (0, 1.00)
    -- 2020 should add up to 100% (or 0% for a few census areas in Alaska that drop on and off)
    or round((population_pct_white_2020 + population_pct_black_2020 + population_pct_am_ind_2020 + population_pct_asian_2020
        + population_pct_pacific_2020 + population_pct_two_races_nh_2020 + population_pct_hispanic_2020), 3) not in (0, 1.00)
;



---- County economic data. Median income and poverty rate ----
-- NOTE: There were some other files that have this data in other years but they were plagued with missing values, etc.
-- For our purposes we can use 2010 numbers as a proxy for the 2000-24 time period.
DROP TABLE IF EXISTS staging__county_economics_overall;
CREATE TABLE staging__county_economics_overall AS
select
    state_fips
        || case when length(replace(cast(county_fips as string), '.0', '')) = 1 then '00'
            when length(replace(cast(county_fips as string), '.0', '')) = 2 then '0'
            else '' end
        || replace(cast(county_fips as string), '.0', '')
        as county_fips,
    state_code,
    county_name,
    cast(replace(median_household_income_2010, ',', '') as int) as median_household_income_2010,
    round(poverty_pct_overall_2010 / 100.0, 5) as poverty_pct_overall_2010,
    round(poverty_pct_under_18_2010 / 100.0, 5) as poverty_pct_under_18_2010
from
    (
    select "State FIPS" as state_fips, "County FIPS" as county_fips, "Postal" as state_code, "Name" as county_name,
    "Median Household Income" as median_household_income_2010, "Poverty Percent All Ages" as poverty_pct_overall_2010,
    "Poverty Percent Under Age 18" as poverty_pct_under_18_2010
    from raw_data__us_census_bureau__county_income_2010
    ) a
;

-- Checks (should return 0 results)
-- Unique FIPS
select county_fips, count(*) from staging__county_economics_overall
where county_fips is not null
group by 1 having count(*) > 1 order by 2 desc, 1;

-- No poverty levels below 0 or over 1.00
select * from staging__county_economics_overall
where poverty_pct_overall_2010 < 0 or poverty_pct_overall_2010 > 1
    or poverty_pct_under_18_2010 < 0 or poverty_pct_under_18_2010 > 1;



---- Educational Attainment ----
    -- Elongate to one row per year, interpolate where years fall between the data points.
DROP TABLE IF EXISTS staging__county_educational_attainment_by_year;
CREATE TABLE staging__county_educational_attainment_by_year AS
select
    case when length(cast("FIPS Code" as text)) = 4 then '0' else '' end
     || "FIPS Code" as county_fips,
    2000 as year,
    round(max(case when "Attribute" = 'Percent of adults with a bachelor''s degree or higher, 2000'
        then "Value" / 100.00 end), 5) as bachelor_degree_pct_of_adults
from raw_data__usda__education2023
group by 1
    union all
select
    case when length(cast("FIPS Code" as text)) = 4 then '0' else '' end
     || "FIPS Code" as county_fips,
    2004 as year,
    -- Interpolate between two data points
    round((max(case when "Attribute" = 'Percent of adults with a bachelor''s degree or higher, 2000'
        then "Value" / 100.00 end)
    + max(case when "Attribute" = 'Percent of adults with a bachelor''s degree or higher, 2008-12'
        then "Value" / 100.00 end)) / 2, 5) as bachelor_degree_pct_of_adults
from raw_data__usda__education2023
group by 1
    union all
select
    case when length(cast("FIPS Code" as text)) = 4 then '0' else '' end
     || "FIPS Code" as county_fips,
    2008 as year,
    max(case when "Attribute" = 'Percent of adults with a bachelor''s degree or higher, 2008-12'
        then "Value" / 100.00 end) as bachelor_degree_pct_of_adults
from raw_data__usda__education2023
group by 1
    union all
select
    case when length(cast("FIPS Code" as text)) = 4 then '0' else '' end
     || "FIPS Code" as county_fips,
    2012 as year,
    round(max(case when "Attribute" = 'Percent of adults with a bachelor''s degree or higher, 2008-12'
        then "Value" / 100.00 end), 5) as bachelor_degree_pct_of_adults
from raw_data__usda__education2023
group by 1
    union all
select
    case when length(cast("FIPS Code" as text)) = 4 then '0' else '' end
     || "FIPS Code" as county_fips,
    2016 as year,
    -- Interpolate between two data points
    round((max(case when "Attribute" = 'Percent of adults with a bachelor''s degree or higher, 2008-12'
        then "Value" / 100.00 end)
    + max(case when "Attribute" = 'Percent of adults with a bachelor''s degree or higher, 2019-23'
        then "Value" / 100.00 end)) / 2, 5) as bachelor_degree_pct_of_adults
from raw_data__usda__education2023
group by 1
    union all
select
    case when length(cast("FIPS Code" as text)) = 4 then '0' else '' end
     || "FIPS Code" as county_fips,
    2020 as year,
    round(max(case when "Attribute" = 'Percent of adults with a bachelor''s degree or higher, 2019-23'
        then "Value" / 100.00 end), 5) as bachelor_degree_pct_of_adults
from raw_data__usda__education2023
group by 1
    union all
select
    case when length(cast("FIPS Code" as text)) = 4 then '0' else '' end
     || "FIPS Code" as county_fips,
    2024 as year,
    round(max(case when "Attribute" = 'Percent of adults with a bachelor''s degree or higher, 2019-23'
        then "Value" / 100.00 end), 5) as bachelor_degree_pct_of_adults
from raw_data__usda__education2023
group by 1
;

-- Checks (should return 0 results)
---- Unique fips_code by year (ignoring blanks)
select county_fips, year, count(*) from staging__county_educational_attainment_by_year
where county_fips is not null
group by 1,2 having count(*) > 1 order by 3 desc, 1, 2;

---- Pct is between 0 and 1.00
select * from staging__county_educational_attainment_by_year 
where bachelor_degree_pct_of_adults < 0 or bachelor_degree_pct_of_adults > 1.00;


---- Educational attainment, flattened ----
DROP TABLE IF EXISTS staging__county_educational_attainment_overall;
CREATE TABLE staging__county_educational_attainment_overall AS
select
    county_fips,
    max(case when year = 2000 then bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2000,
    max(case when year = 2004 then bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2004,
    max(case when year = 2008 then bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2008,
    max(case when year = 2012 then bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2012,
    max(case when year = 2016 then bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2016,
    max(case when year = 2020 then bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2020,
    max(case when year = 2024 then bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2024
from
    staging__county_educational_attainment_by_year
group by 1
;

-- Checks (should return 0 results)
-- Unique FIPS
select county_fips, count(*) from staging__county_educational_attainment_overall
where county_fips is not null
group by 1 having count(*) > 1 order by 2 desc, 1;


.quit
