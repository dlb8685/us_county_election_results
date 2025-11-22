
# Make sure you are in the correct project directory.
# cd /Users/danbryan/Personal/us_county_election_results

# Activate the python environment
source us_county_election_results_venv/bin/activate

# Install packages needed
pip install -r requirements.txt

# In theory this could automate the data pulls from third-party sources.
# In practice they require accepting conditions, clicking "OK", etc. that prevent programmatic access.
# python pipeline/load_urls_to_csv.py

# This will load raw data csvs into a sqlite database, as-is.
python pipeline/load_csvs_to_raw_data_tables.py

# sqlite3 us_county_election_results.db
# Run specific files to process raw data with sqlite
sqlite3 us_county_election_results.db < pipeline/transform_raw_data_to_staging.sql
sqlite3 us_county_election_results.db < pipeline/transform_staging_to_final.sql

# This loads the final tables from processing into csv's that can be used by the front-end analytics side.
python pipeline/save_datatables_to_csv.py
