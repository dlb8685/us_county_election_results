import pandas as pd
import sqlite3


def load_csv_to_sqlite(input_file_name, output_table_name, con):
    print(f"Loading {input_file_name} to {output_table_name} ...")
    df = pd.read_csv(input_file_name)
    df.to_sql(name=output_table_name, con=con, if_exists="replace")
    del df
    return True


if __name__ == '__main__':
    ## Get every file into a sqlite table as early in the process as possible.
    con = sqlite3.connect("us_county_election_results.db")

    # MIT Election Labs
    ## County-level election results
    load_csv_to_sqlite(
        "data/raw_data/mit_election_labs__countypres_2000-2024.csv",
        "raw_data__mit_election_labs__countypres_2000_2024",
        con
    )
    ## Second data set for 2024 results (MIT is messy)
    load_csv_to_sqlite(
        "data/raw_data/tonmcg__2024_US_County_Level_Presidential_Results.csv",
        "raw_data__tonmcg__countypres_2024",
        con
    )

    # U.S. Census Bureau
    ## 2010
    ## NOTE: need to make sure csv is saved with UTF-8 encoding, the Census Bureau doesn't do that.
    load_csv_to_sqlite(
        "data/raw_data/us_census_bureau__cc-est2019-alldata.csv",
        "raw_data__us_census_bureau__cc_est2019_alldata",
        con
    )
    ## 2020
    ## NOTE: need to make sure csv is saved with UTF-8 encoding, the Census Bureau doesn't do that.
    load_csv_to_sqlite(
        "data/raw_data/us_census_bureau__cc-est2024-alldata.csv",
        "raw_data__us_census_bureau__county_demographics_2020",
        con
    )
    ## County-level median income / economics
    ## 2010
    load_csv_to_sqlite(
        "data/raw_data/us_census_bureau__est10all.csv",
        "raw_data__us_census_bureau__county_income_2010",
        con
    )
    
    # National Bureau of Economic Research (NBER)
    ## County-level demographics
    ## 2000
    load_csv_to_sqlite("data/raw_data/nber__coest00intalldata.csv", "raw_data__nber__coest00intalldata", con)
    
    # U.S. Dept. of Agriculture (USDA), Economic Research Service
    # 2020
    ## NOTE: need to make sure Education2023 is saved wth UTF-8 encoding, USDA file doesn't do that.
    load_csv_to_sqlite("data/raw_data/usda__Poverty2023.csv", "raw_data__usda__poverty2023", con)
    load_csv_to_sqlite("data/raw_data/usda__Unemployment2023.csv", "raw_data__usda__unemployment2023", con)
    load_csv_to_sqlite("data/raw_data/usda__Education2023.csv", "raw_data__usda__education2023", con)

    # The Historical Marker Database (HMDB)
    ## County Seat of each county (not on other data sets)
    load_csv_to_sqlite("data/raw_data/hmdb__county_seats.csv", "raw_data__hmdb__county_seats", con)
