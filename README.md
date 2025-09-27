# us_county_election_results
A project to create and analyze data from U.S. elections, primarily at the county-level.


## Raw Data

### raw_data/mit_election_labs
countypres_2000-2024.csv | https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ#
MIT Election Data and Science Lab, 2018, "County Presidential Election Returns 2000-2024", https://doi.org/10.7910/DVN/VOQCHQ, Harvard Dataverse, V16, UNF:6:NKTy7eW9uEWX4imXpPxf5g== [fileUNF]

NOTE:
 - Shannon County, SD was changed to Oglala County after 2012 and the FIPS was changed from 46113 to 46102. For consistency, I changed all Shannon County FIPS to 46102, and updated the county name.
 - Broomfield County, Colorado was not created until 2001.
 - The city and county of Bedford, VA merged in 2013. For 2012 and earlier there will be "duplicate" results for FIPS 51019 and 51515, then 51515 "goes away" in 2016. For consistency, all of them should have 51019 and be combined in analysis.
 - Jackson County and Kansas City, MO have a weird overlap. Most datasets consider them as a single unit but this has them separately. Updated the FIPS so that both of these are 29095 (Jackson County). Even wikipedia has all results added up under Jackson County.
 - Alaska is a weird outlier. A lot of "districts" in Alaska *only* have data here and on none of the other data sets. Will count Alaska as one unit, state-level. I have seen a couple of sites that do this in the past (but I don't remember which ones...)


### raw_data/us_census_bureau

cc-est2024-agesex-all.csv | https://www2.census.gov/programs-surveys/popest/datasets/2020-2024/counties/asrh/cc-est2024-agesex-all.csv
cc-est2024-alldata.csv | https://www2.census.gov/programs-surveys/popest/datasets/2020-2024/counties/asrh/cc-est2024-alldata.csv

County Population by Characteristics: 2020-2024 (https://www.census.gov/data/tables/time-series/demo/popest/2020s-counties-detail.html)


