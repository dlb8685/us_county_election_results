import pandas as pd

def load_url_to_csv(url, csv_path):
    print(f"Reading file {url}")
    df = pd.read_csv(url)
    print(f"Saving data to {csv_path}")
    df.to_csv(csv_path, index=False)
    return True

# Full list of source files for programmatic download.
# However, many of these require the user to manually accept or self-certify licensed use, requiring manual downloads.
source_files = [
    # MIT Election Labs
    {"url": "https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ#",
        "csv_path": "data/raw_data/mit_election_labs__countypres_2000-2024.csv",
        "allows_url_download": False},
    # U.S. Census Bureau
    {"url": "https://www2.census.gov/programs-surveys/popest/datasets/2020-2024/counties/asrh/cc-est2024-agesex-all.csv",
        "csv_path": "data/raw_data/us_census_bureau__cc-est2024-agesex-all.csv",
        "allows_url_download": False},
    {"url": "https://www2.census.gov/programs-surveys/popest/datasets/2020-2024/counties/asrh/cc-est2024-alldata.csv",
        "csv_path": "data/raw_data/us_census_bureau__cc-est2024-alldata.csv",
        "allows_url_download": False},
    {"url": "https://www2.census.gov/programs-surveys/decennial/tables/time-series/historical-income-counties/county1.csv",
        "csv_path": "data/raw_data/us_census_bureau__median_income_county1.csv",
        "allows_url_download": False},
    {"url": "https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/asrh/cc-est2019-alldata.csv",
        "csv_path": "data/raw_data/us_census_bureau__cc-est2019-alldata.csv",
        "allows_url_download": False}
]

for file in source_files:
    if file["allows_url_download"]:
        load_url_to_csv(file["url"], file["csv_path"])


