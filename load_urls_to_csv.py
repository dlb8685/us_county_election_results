import pandas as pd

def load_url_to_csv(url, csv_path):
    print(f"Reading file {url}")
    df = pd.read_csv(url)
    print(f"Saving data to {csv_path}")
    df.to_csv(csv_path, index=False)
    return True

source_files = [
    {"url": "https://dataverse.harvard.edu/file.xhtml?fileId=8092662&version=12.0#", "csv_path": "data/countypres_2000-2020.csv", "allows_url_download": False}
]

for file in source_files:
    if file["allows_url_download"]:
        load_url_to_csv(file["url"], file["csv_path"])


