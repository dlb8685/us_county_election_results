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

-- All results outside of a couple known exceptions, matched voting to population data.
select county_fips, county_name, state_abbr, year,  votes_total
from final__county_election_data_by_year 
where population_total is null
    and county_fips is not null --  <- some random states have non-county level data
    and state_abbr <> 'AK' --    <- We know AK is a weird state
;




DROP TABLE IF EXISTS final__county_election_data_overall;
CREATE TABLE final__county_election_data_overall AS
select
    -- Identifiers
    cd.county_fips,
    cd.county_name,
    cd.county_seat,
    cd.state_name,
    cd.state_abbr,
    -- Economics (all years)
    cd.median_household_income_2010,
    cd.poverty_pct_overall_2010,
    cd.poverty_pct_under_18_2010,
    -- 2000
        -- Demographics
    max(case when cd.year = 2000 then cd.population_total end) as population_total_2000,
    max(case when cd.year = 2000 then cd.population_white end) as population_white_2000,
    max(case when cd.year = 2000 then cd.population_black end) as population_black_2000,
    max(case when cd.year = 2000 then cd.population_am_ind end) as population_am_ind_2000,
    max(case when cd.year = 2000 then cd.population_asian end) as population_asian_2000,
    max(case when cd.year = 2000 then cd.population_pacific end) as population_pacific_2000,
    max(case when cd.year = 2000 then cd.population_two_races_nh end) as population_two_races_nh_2000,
    max(case when cd.year = 2000 then cd.population_hispanic end) as population_hispanic_2000,
    max(case when cd.year = 2000 then cd.population_over_18_total end) as population_over_18_total_2000,
    max(case when cd.year = 2000 then cd.population_pct_white end) as population_pct_white_2000,
    max(case when cd.year = 2000 then cd.population_pct_black end) as population_pct_black_2000,
    max(case when cd.year = 2000 then cd.population_pct_am_ind end) as population_pct_am_ind_2000,
    max(case when cd.year = 2000 then cd.population_pct_asian end) as population_pct_asian_2000,
    max(case when cd.year = 2000 then cd.population_pct_pacific end) as population_pct_pacific_2000,
    max(case when cd.year = 2000 then cd.population_pct_two_races_nh end) as population_pct_two_races_nh_2000,
    max(case when cd.year = 2000 then cd.population_pct_hispanic end) as population_pct_hispanic_2000,
    max(case when cd.year = 2000 then cd.population_pct_over_18 end) as population_pct_over_18_2000,
        -- Educational Attainment
    max(case when cd.year = 2000 then cd.bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2000,
        -- Voting results
    max(case when cd.year = 2000 then cd.votes_democrat end) as votes_democrat_2000,
    max(case when cd.year = 2000 then cd.votes_republican end) as votes_republican_2000,
    max(case when cd.year = 2000 then cd.votes_other end) as votes_other_2000,
    max(case when cd.year = 2000 then cd.votes_total end) as votes_total_2000,
    max(case when cd.year = 2000 then cd.votes_pct_democrat end) as votes_pct_democrat_2000,
    max(case when cd.year = 2000 then cd.votes_pct_republican end) as votes_pct_republican_2000,
    max(case when cd.year = 2000 then cd.votes_pct_other end) as votes_pct_other_2000,
    max(case when cd.year = 2000 then cd.votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2000,
    max(case when cd.year = 2000 then cd.votes_pct_two_party_republican end) as votes_pct_two_party_republican_2000,
    max(case when cd.year = 2000 then cd.winning_party end) as winning_party_2000,
    max(case when cd.year = 2000 then cd.winning_margin end) as winning_margin_2000,
    max(case when cd.year = 2000 then cd.winning_two_party_margin end) as winning_two_party_margin_2000,
    max(case when cd.year = 2000 then cd.votes_pct_partisan_index end) as votes_pct_partisan_index_2000,
    -- 2004
        -- Demographics
    max(case when cd.year = 2004 then cd.population_total end) as population_total_2004,
    max(case when cd.year = 2004 then cd.population_white end) as population_white_2004,
    max(case when cd.year = 2004 then cd.population_black end) as population_black_2004,
    max(case when cd.year = 2004 then cd.population_am_ind end) as population_am_ind_2004,
    max(case when cd.year = 2004 then cd.population_asian end) as population_asian_2004,
    max(case when cd.year = 2004 then cd.population_pacific end) as population_pacific_2004,
    max(case when cd.year = 2004 then cd.population_two_races_nh end) as population_two_races_nh_2004,
    max(case when cd.year = 2004 then cd.population_hispanic end) as population_hispanic_2004,
    max(case when cd.year = 2004 then cd.population_over_18_total end) as population_over_18_total_2004,
    max(case when cd.year = 2004 then cd.population_pct_white end) as population_pct_white_2004,
    max(case when cd.year = 2004 then cd.population_pct_black end) as population_pct_black_2004,
    max(case when cd.year = 2004 then cd.population_pct_am_ind end) as population_pct_am_ind_2004,
    max(case when cd.year = 2004 then cd.population_pct_asian end) as population_pct_asian_2004,
    max(case when cd.year = 2004 then cd.population_pct_pacific end) as population_pct_pacific_2004,
    max(case when cd.year = 2004 then cd.population_pct_two_races_nh end) as population_pct_two_races_nh_2004,
    max(case when cd.year = 2004 then cd.population_pct_hispanic end) as population_pct_hispanic_2004,
    max(case when cd.year = 2004 then cd.population_pct_over_18 end) as population_pct_over_18_2004,
        -- Educational Attainment
    max(case when cd.year = 2004 then cd.bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2004,
        -- Voting results
    max(case when cd.year = 2004 then cd.votes_democrat end) as votes_democrat_2004,
    max(case when cd.year = 2004 then cd.votes_republican end) as votes_republican_2004,
    max(case when cd.year = 2004 then cd.votes_other end) as votes_other_2004,
    max(case when cd.year = 2004 then cd.votes_total end) as votes_total_2004,
    max(case when cd.year = 2004 then cd.votes_pct_democrat end) as votes_pct_democrat_2004,
    max(case when cd.year = 2004 then cd.votes_pct_republican end) as votes_pct_republican_2004,
    max(case when cd.year = 2004 then cd.votes_pct_other end) as votes_pct_other_2004,
    max(case when cd.year = 2004 then cd.votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2004,
    max(case when cd.year = 2004 then cd.votes_pct_two_party_republican end) as votes_pct_two_party_republican_2004,
    max(case when cd.year = 2004 then cd.winning_party end) as winning_party_2004,
    max(case when cd.year = 2004 then cd.winning_margin end) as winning_margin_2004,
    max(case when cd.year = 2004 then cd.winning_two_party_margin end) as winning_two_party_margin_2004,
    max(case when cd.year = 2004 then cd.votes_pct_partisan_index end) as votes_pct_partisan_index_2004,
    max(case when cd.year = 2004 then cd.votes_pct_swing_from_prev_election end) as votes_pct_swing_from_prev_election_2004,
    -- 2008
        -- Demographics
    max(case when cd.year = 2008 then cd.population_total end) as population_total_2008,
    max(case when cd.year = 2008 then cd.population_white end) as population_white_2008,
    max(case when cd.year = 2008 then cd.population_black end) as population_black_2008,
    max(case when cd.year = 2008 then cd.population_am_ind end) as population_am_ind_2008,
    max(case when cd.year = 2008 then cd.population_asian end) as population_asian_2008,
    max(case when cd.year = 2008 then cd.population_pacific end) as population_pacific_2008,
    max(case when cd.year = 2008 then cd.population_two_races_nh end) as population_two_races_nh_2008,
    max(case when cd.year = 2008 then cd.population_hispanic end) as population_hispanic_2008,
    max(case when cd.year = 2008 then cd.population_over_18_total end) as population_over_18_total_2008,
    max(case when cd.year = 2008 then cd.population_pct_white end) as population_pct_white_2008,
    max(case when cd.year = 2008 then cd.population_pct_black end) as population_pct_black_2008,
    max(case when cd.year = 2008 then cd.population_pct_am_ind end) as population_pct_am_ind_2008,
    max(case when cd.year = 2008 then cd.population_pct_asian end) as population_pct_asian_2008,
    max(case when cd.year = 2008 then cd.population_pct_pacific end) as population_pct_pacific_2008,
    max(case when cd.year = 2008 then cd.population_pct_two_races_nh end) as population_pct_two_races_nh_2008,
    max(case when cd.year = 2008 then cd.population_pct_hispanic end) as population_pct_hispanic_2008,
    max(case when cd.year = 2008 then cd.population_pct_over_18 end) as population_pct_over_18_2008,
        -- Educational Attainment
    max(case when cd.year = 2008 then cd.bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2008,
        -- Voting results
    max(case when cd.year = 2008 then cd.votes_democrat end) as votes_democrat_2008,
    max(case when cd.year = 2008 then cd.votes_republican end) as votes_republican_2008,
    max(case when cd.year = 2008 then cd.votes_other end) as votes_other_2008,
    max(case when cd.year = 2008 then cd.votes_total end) as votes_total_2008,
    max(case when cd.year = 2008 then cd.votes_pct_democrat end) as votes_pct_democrat_2008,
    max(case when cd.year = 2008 then cd.votes_pct_republican end) as votes_pct_republican_2008,
    max(case when cd.year = 2008 then cd.votes_pct_other end) as votes_pct_other_2008,
    max(case when cd.year = 2008 then cd.votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2008,
    max(case when cd.year = 2008 then cd.votes_pct_two_party_republican end) as votes_pct_two_party_republican_2008,
    max(case when cd.year = 2008 then cd.winning_party end) as winning_party_2008,
    max(case when cd.year = 2008 then cd.winning_margin end) as winning_margin_2008,
    max(case when cd.year = 2008 then cd.winning_two_party_margin end) as winning_two_party_margin_2008,
    max(case when cd.year = 2008 then cd.votes_pct_partisan_index end) as votes_pct_partisan_index_2008,
    max(case when cd.year = 2008 then cd.votes_pct_swing_from_prev_election end) as votes_pct_swing_from_prev_election_2008,
    -- 2012
        -- Demographics
    max(case when cd.year = 2012 then cd.population_total end) as population_total_2012,
    max(case when cd.year = 2012 then cd.population_white end) as population_white_2012,
    max(case when cd.year = 2012 then cd.population_black end) as population_black_2012,
    max(case when cd.year = 2012 then cd.population_am_ind end) as population_am_ind_2012,
    max(case when cd.year = 2012 then cd.population_asian end) as population_asian_2012,
    max(case when cd.year = 2012 then cd.population_pacific end) as population_pacific_2012,
    max(case when cd.year = 2012 then cd.population_two_races_nh end) as population_two_races_nh_2012,
    max(case when cd.year = 2012 then cd.population_hispanic end) as population_hispanic_2012,
    max(case when cd.year = 2012 then cd.population_over_18_total end) as population_over_18_total_2012,
    max(case when cd.year = 2012 then cd.population_pct_white end) as population_pct_white_2012,
    max(case when cd.year = 2012 then cd.population_pct_black end) as population_pct_black_2012,
    max(case when cd.year = 2012 then cd.population_pct_am_ind end) as population_pct_am_ind_2012,
    max(case when cd.year = 2012 then cd.population_pct_asian end) as population_pct_asian_2012,
    max(case when cd.year = 2012 then cd.population_pct_pacific end) as population_pct_pacific_2012,
    max(case when cd.year = 2012 then cd.population_pct_two_races_nh end) as population_pct_two_races_nh_2012,
    max(case when cd.year = 2012 then cd.population_pct_hispanic end) as population_pct_hispanic_2012,
    max(case when cd.year = 2012 then cd.population_pct_over_18 end) as population_pct_over_18_2012,
        -- Educational Attainment
    max(case when cd.year = 2012 then cd.bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2012,
        -- Voting results
    max(case when cd.year = 2012 then cd.votes_democrat end) as votes_democrat_2012,
    max(case when cd.year = 2012 then cd.votes_republican end) as votes_republican_2012,
    max(case when cd.year = 2012 then cd.votes_other end) as votes_other_2012,
    max(case when cd.year = 2012 then cd.votes_total end) as votes_total_2012,
    max(case when cd.year = 2012 then cd.votes_pct_democrat end) as votes_pct_democrat_2012,
    max(case when cd.year = 2012 then cd.votes_pct_republican end) as votes_pct_republican_2012,
    max(case when cd.year = 2012 then cd.votes_pct_other end) as votes_pct_other_2012,
    max(case when cd.year = 2012 then cd.votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2012,
    max(case when cd.year = 2012 then cd.votes_pct_two_party_republican end) as votes_pct_two_party_republican_2012,
    max(case when cd.year = 2012 then cd.winning_party end) as winning_party_2012,
    max(case when cd.year = 2012 then cd.winning_margin end) as winning_margin_2012,
    max(case when cd.year = 2012 then cd.winning_two_party_margin end) as winning_two_party_margin_2012,
    max(case when cd.year = 2012 then cd.votes_pct_partisan_index end) as votes_pct_partisan_index_2012,
    max(case when cd.year = 2012 then cd.votes_pct_swing_from_prev_election end) as votes_pct_swing_from_prev_election_2012,
    -- 2016
        -- Demographics
    max(case when cd.year = 2016 then cd.population_total end) as population_total_2016,
    max(case when cd.year = 2016 then cd.population_white end) as population_white_2016,
    max(case when cd.year = 2016 then cd.population_black end) as population_black_2016,
    max(case when cd.year = 2016 then cd.population_am_ind end) as population_am_ind_2016,
    max(case when cd.year = 2016 then cd.population_asian end) as population_asian_2016,
    max(case when cd.year = 2016 then cd.population_pacific end) as population_pacific_2016,
    max(case when cd.year = 2016 then cd.population_two_races_nh end) as population_two_races_nh_2016,
    max(case when cd.year = 2016 then cd.population_hispanic end) as population_hispanic_2016,
    max(case when cd.year = 2016 then cd.population_over_18_total end) as population_over_18_total_2016,
    max(case when cd.year = 2016 then cd.population_pct_white end) as population_pct_white_2016,
    max(case when cd.year = 2016 then cd.population_pct_black end) as population_pct_black_2016,
    max(case when cd.year = 2016 then cd.population_pct_am_ind end) as population_pct_am_ind_2016,
    max(case when cd.year = 2016 then cd.population_pct_asian end) as population_pct_asian_2016,
    max(case when cd.year = 2016 then cd.population_pct_pacific end) as population_pct_pacific_2016,
    max(case when cd.year = 2016 then cd.population_pct_two_races_nh end) as population_pct_two_races_nh_2016,
    max(case when cd.year = 2016 then cd.population_pct_hispanic end) as population_pct_hispanic_2016,
    max(case when cd.year = 2016 then cd.population_pct_over_18 end) as population_pct_over_18_2016,
        -- Educational Attainment
    max(case when cd.year = 2016 then cd.bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2016,
        -- Voting results
    max(case when cd.year = 2016 then cd.votes_democrat end) as votes_democrat_2016,
    max(case when cd.year = 2016 then cd.votes_republican end) as votes_republican_2016,
    max(case when cd.year = 2016 then cd.votes_other end) as votes_other_2016,
    max(case when cd.year = 2016 then cd.votes_total end) as votes_total_2016,
    max(case when cd.year = 2016 then cd.votes_pct_democrat end) as votes_pct_democrat_2016,
    max(case when cd.year = 2016 then cd.votes_pct_republican end) as votes_pct_republican_2016,
    max(case when cd.year = 2016 then cd.votes_pct_other end) as votes_pct_other_2016,
    max(case when cd.year = 2016 then cd.votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2016,
    max(case when cd.year = 2016 then cd.votes_pct_two_party_republican end) as votes_pct_two_party_republican_2016,
    max(case when cd.year = 2016 then cd.winning_party end) as winning_party_2016,
    max(case when cd.year = 2016 then cd.winning_margin end) as winning_margin_2016,
    max(case when cd.year = 2016 then cd.winning_two_party_margin end) as winning_two_party_margin_2016,
    max(case when cd.year = 2016 then cd.votes_pct_partisan_index end) as votes_pct_partisan_index_2016,
    max(case when cd.year = 2016 then cd.votes_pct_swing_from_prev_election end) as votes_pct_swing_from_prev_election_2016,
    -- 2020
        -- Demographics
    max(case when cd.year = 2020 then cd.population_total end) as population_total_2020,
    max(case when cd.year = 2020 then cd.population_white end) as population_white_2020,
    max(case when cd.year = 2020 then cd.population_black end) as population_black_2020,
    max(case when cd.year = 2020 then cd.population_am_ind end) as population_am_ind_2020,
    max(case when cd.year = 2020 then cd.population_asian end) as population_asian_2020,
    max(case when cd.year = 2020 then cd.population_pacific end) as population_pacific_2020,
    max(case when cd.year = 2020 then cd.population_two_races_nh end) as population_two_races_nh_2020,
    max(case when cd.year = 2020 then cd.population_hispanic end) as population_hispanic_2020,
    max(case when cd.year = 2020 then cd.population_over_18_total end) as population_over_18_total_2020,
    max(case when cd.year = 2020 then cd.population_pct_white end) as population_pct_white_2020,
    max(case when cd.year = 2020 then cd.population_pct_black end) as population_pct_black_2020,
    max(case when cd.year = 2020 then cd.population_pct_am_ind end) as population_pct_am_ind_2020,
    max(case when cd.year = 2020 then cd.population_pct_asian end) as population_pct_asian_2020,
    max(case when cd.year = 2020 then cd.population_pct_pacific end) as population_pct_pacific_2020,
    max(case when cd.year = 2020 then cd.population_pct_two_races_nh end) as population_pct_two_races_nh_2020,
    max(case when cd.year = 2020 then cd.population_pct_hispanic end) as population_pct_hispanic_2020,
    max(case when cd.year = 2020 then cd.population_pct_over_18 end) as population_pct_over_18_2020,
        -- Educational Attainment
    max(case when cd.year = 2020 then cd.bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2020,
        -- Voting results
    max(case when cd.year = 2020 then cd.votes_democrat end) as votes_democrat_2020,
    max(case when cd.year = 2020 then cd.votes_republican end) as votes_republican_2020,
    max(case when cd.year = 2020 then cd.votes_other end) as votes_other_2020,
    max(case when cd.year = 2020 then cd.votes_total end) as votes_total_2020,
    max(case when cd.year = 2020 then cd.votes_pct_democrat end) as votes_pct_democrat_2020,
    max(case when cd.year = 2020 then cd.votes_pct_republican end) as votes_pct_republican_2020,
    max(case when cd.year = 2020 then cd.votes_pct_other end) as votes_pct_other_2020,
    max(case when cd.year = 2020 then cd.votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2020,
    max(case when cd.year = 2020 then cd.votes_pct_two_party_republican end) as votes_pct_two_party_republican_2020,
    max(case when cd.year = 2020 then cd.winning_party end) as winning_party_2020,
    max(case when cd.year = 2020 then cd.winning_margin end) as winning_margin_2020,
    max(case when cd.year = 2020 then cd.winning_two_party_margin end) as winning_two_party_margin_2020,
    max(case when cd.year = 2020 then cd.votes_pct_partisan_index end) as votes_pct_partisan_index_2020,
    max(case when cd.year = 2020 then cd.votes_pct_swing_from_prev_election end) as votes_pct_swing_from_prev_election_2020,
    -- 2024
        -- Demographics
    max(case when cd.year = 2024 then cd.population_total end) as population_total_2024,
    max(case when cd.year = 2024 then cd.population_white end) as population_white_2024,
    max(case when cd.year = 2024 then cd.population_black end) as population_black_2024,
    max(case when cd.year = 2024 then cd.population_am_ind end) as population_am_ind_2024,
    max(case when cd.year = 2024 then cd.population_asian end) as population_asian_2024,
    max(case when cd.year = 2024 then cd.population_pacific end) as population_pacific_2024,
    max(case when cd.year = 2024 then cd.population_two_races_nh end) as population_two_races_nh_2024,
    max(case when cd.year = 2024 then cd.population_hispanic end) as population_hispanic_2024,
    max(case when cd.year = 2024 then cd.population_over_18_total end) as population_over_18_total_2024,
    max(case when cd.year = 2024 then cd.population_pct_white end) as population_pct_white_2024,
    max(case when cd.year = 2024 then cd.population_pct_black end) as population_pct_black_2024,
    max(case when cd.year = 2024 then cd.population_pct_am_ind end) as population_pct_am_ind_2024,
    max(case when cd.year = 2024 then cd.population_pct_asian end) as population_pct_asian_2024,
    max(case when cd.year = 2024 then cd.population_pct_pacific end) as population_pct_pacific_2024,
    max(case when cd.year = 2024 then cd.population_pct_two_races_nh end) as population_pct_two_races_nh_2024,
    max(case when cd.year = 2024 then cd.population_pct_hispanic end) as population_pct_hispanic_2024,
    max(case when cd.year = 2024 then cd.population_pct_over_18 end) as population_pct_over_18_2024,
        -- Educational Attainment
    max(case when cd.year = 2024 then cd.bachelor_degree_pct_of_adults end) as bachelor_degree_pct_of_adults_2024,
        -- Voting results
    max(case when cd.year = 2024 then cd.votes_democrat end) as votes_democrat_2024,
    max(case when cd.year = 2024 then cd.votes_republican end) as votes_republican_2024,
    max(case when cd.year = 2024 then cd.votes_other end) as votes_other_2024,
    max(case when cd.year = 2024 then cd.votes_total end) as votes_total_2024,
    max(case when cd.year = 2024 then cd.votes_pct_democrat end) as votes_pct_democrat_2024,
    max(case when cd.year = 2024 then cd.votes_pct_republican end) as votes_pct_republican_2024,
    max(case when cd.year = 2024 then cd.votes_pct_other end) as votes_pct_other_2024,
    max(case when cd.year = 2024 then cd.votes_pct_two_party_democrat end) as votes_pct_two_party_democrat_2024,
    max(case when cd.year = 2024 then cd.votes_pct_two_party_republican end) as votes_pct_two_party_republican_2024,
    max(case when cd.year = 2024 then cd.winning_party end) as winning_party_2024,
    max(case when cd.year = 2024 then cd.winning_margin end) as winning_margin_2024,
    max(case when cd.year = 2024 then cd.winning_two_party_margin end) as winning_two_party_margin_2024,
    max(case when cd.year = 2024 then cd.votes_pct_partisan_index end) as votes_pct_partisan_index_2024,
    max(case when cd.year = 2024 then cd.votes_pct_swing_from_prev_election end) as votes_pct_swing_from_prev_election_2024
from
    final__county_election_data_by_year cd
group by
    1,2,3,4,5,6,7,8
;


-- Checks (should return 0 results)
-- Unique FIPS
select county_fips, count(*) from final__county_election_data_overall
where county_fips is not null
group by 1 having count(*) > 1 order by 2 desc, 1;
