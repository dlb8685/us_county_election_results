-- sqlite3 us_county_election_results.db
.header on
.mode column


/*
Tables Used from Staging:
 - staging__county_seats
 - staging__county_election_results_by_year
 - staging__county_election_results_overall
 - staging__county_demographics_by_year
 - staging__county_demographics_overall
 - staging__county_economics_overall
 - staging__county_educational_attainment_by_year
 - staging__county_educational_attainment_overall
*/


DROP TABLE IF EXISTS final__county_election_data_by_year;
CREATE TABLE final__county_election_data_by_year AS
select
    -- Identifiers
    res.county_fips,
    replace(replace(
        coalesce(d.county_name, cs.county_name, res.county_name), ' County', ''
        ), ' Parish', ''
    ) as county_name,
    cs.county_seat as county_seat,
    coalesce(d.state_name, res.state_name) as state_name,
    res.state_abbr,
    -- Year
    res.year,
    -- Demographics
    d.population_total,
    d.population_white,
    d.population_black,
    d.population_am_ind,
    d.population_asian,
    d.population_pacific,
    d.population_two_races_nh,
    d.population_hispanic,
    d.population_over_18_total,
    d.population_pct_white,
    d.population_pct_black,
    d.population_pct_am_ind,
    d.population_pct_asian,
    d.population_pct_pacific,
    d.population_pct_two_races_nh,
    d.population_pct_hispanic,
    d.population_pct_over_18,
    -- Educational Attainment
    e.bachelor_degree_pct_of_adults,
    -- Economics
    ec.median_household_income_2010,
    ec.poverty_pct_overall_2010,
    ec.poverty_pct_under_18_2010,
    -- Voting results
    res.votes_democrat,
    res.votes_republican,
    res.votes_other,
    res.votes_total,
    res.votes_pct_democrat,
    res.votes_pct_republican,
    res.votes_pct_other,
    res.votes_pct_two_party_democrat,
    res.votes_pct_two_party_republican,
    res.winning_party,
    res.winning_margin,
    res.winning_two_party_margin,
    res.votes_pct_partisan_index,
    res.votes_pct_swing_from_prev_election
from
    staging__county_election_results_by_year res
    left join staging__county_seats cs
        on cs.county_fips = res.county_fips
    -- pre-aggregated data at the county_fips + year grain for other metrics
    left join staging__county_demographics_by_year d
        on d.county_fips = res.county_fips
        and d.year = res.year
    left join staging__county_educational_attainment_by_year e
        on e.county_fips = res.county_fips
        and e.year = res.year
    -- exception: economics data we only have for 2010, but that's in the middle of our time period
    -- We just clearly specify whether it's 2000 or 2024 that economic indicators are for 2010
    left join staging__county_economics_overall ec
        on ec.county_fips = res.county_fips
;

-- Checks (should return 0 results)
-- Unique FIPS
select county_fips, year, count(*) from final__county_election_data_by_year
where county_fips is not null
group by 1,2 having count(*) > 1 order by 3 desc, 1, 2;

-- 
select county_fips, county_name, state_abbr, year,  votes_total
from final__county_election_data_by_year 
where population_total is null
    and county_fips is not null --  <- some random states have non-county level data
    and state_abbr <> 'AK' --    <- We know AK is a weird state
;

select distinct county_fips, county_name, state_abbr from final__county_election_data_by_year where state_abbr = 'RI'
order by 1,2,3;

select county_fips, county_name, state_abbr, votes_total, population_total
from final__county_election_data_by_year  where county_fips in ('18146');

select county_fips, county_name, state_abbr, year, votes_total, population_total
from final__county_election_data_by_year where state_abbr = 'LA'
order by 2,1,3,4,5;

county_fips  county_name  state_abbr  year  votes_total
-----------  -----------  ----------  ----  -----------
04029        YUMA         AZ          2024  68910      
06117        YUBA         CA          2024  29817      
13203        MITCHELL     GA          2024  8877       


select *, case when year < 2024 and party not in ('UNDERVOTES', 'OVERVOTES') then candidatevotes
                    when year = 2024 and state_po not in ('AR', 'AZ', 'LA', 'OK', 'PA', 'SC', 'TX') and party not in ('UNDERVOTES', 'OVERVOTES') then candidatevotes
                    when year = 2024 and state_po in ('AR', 'AZ', 'LA', 'OK', 'PA', 'SC', 'TX') and party not in ('UNDERVOTES', 'OVERVOTES') and mode in ('TOTAL', 'TOTAL VOTES') then candidatevotes
                    else 0 end
from raw_data__mit_election_labs__countypres_2000_2024
where year = 2024 and state_po = 'TX';       
                    


DROP TABLE IF EXISTS final__county_election_data_overall;
CREATE TABLE final__county_election_data_overall AS
select
    -- Identifiers
    cd.county_fips,
    cd.county_name,
    cd.county_seat,
    cd.state_name,
    cd.state_abbr,
    -- Year
    cd.year,
    -- Economics (all years)
    ec.median_household_income_2010,
    ec.poverty_pct_overall_2010,
    ec.poverty_pct_under_18_2010,
    -- 2000
    case when cd.year = 2000 then cd.population_total end as population_total_2000,
    case when cd.year = 2000 then cd.population_white end as population_white_2000,
    case when cd.year = 2000 then cd.population_black end as population_black_2000,
    case when cd.year = 2000 then cd.population_am_ind end as population_am_ind_2000,
    case when cd.year = 2000 then cd.population_asian end as population_asian_2000,
    case when cd.year = 2000 then cd.population_pacific end as population_pacific_2000,
    case when cd.year = 2000 then cd.population_two_races_nh end as population_two_races_nh_2000,
    case when cd.year = 2000 then cd.population_hispanic end as population_hispanic_2000,
    case when cd.year = 2000 then cd.population_over_18_total end as population_over_18_total_2000,
    case when cd.year = 2000 then cd.population_pct_white end as population_pct_white_2000,
    case when cd.year = 2000 then cd.population_pct_black end as population_pct_black_2000,
    case when cd.year = 2000 then cd.population_pct_am_ind end as population_pct_am_ind_2000,
    case when cd.year = 2000 then cd.population_pct_asian end as population_pct_asian_2000,
    case when cd.year = 2000 then cd.population_pct_pacific end as population_pct_pacific_2000,
    case when cd.year = 2000 then cd.population_pct_two_races_nh end as population_pct_two_races_nh_2000,
    case when cd.year = 2000 then cd.population_pct_hispanic end as population_pct_hispanic_2000,
    case when cd.year = 2000 then cd.population_pct_over_18 end as population_pct_over_18_2000,
    -- Educational Attainment
    e.bachelor_degree_pct_of_adults,
    -- Voting results
    res.votes_democrat,
    res.votes_republican,
    res.votes_other,
    res.votes_total,
    res.votes_pct_democrat,
    res.votes_pct_republican,
    res.votes_pct_other,
    res.votes_pct_two_party_democrat,
    res.votes_pct_two_party_republican,
    res.winning_party,
    res.winning_margin,
    res.winning_two_party_margin,
    res.votes_pct_partisan_index,
    res.votes_pct_swing_from_prev_election
from
    final__county_election_data_by_year cd
;