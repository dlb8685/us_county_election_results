# Creating main environment
python3 -m venv us_county_election_results_venv
source us_county_election_results_venv/bin/activate
pip install -r requirements.txt


# Creating a Dash-specific environment
# Clean separation from main, run from top-level of repo
python3 -m venv dash_app_venv
source dash_app_venv/bin/activate
pip install -r dash_app/requirements.txt

