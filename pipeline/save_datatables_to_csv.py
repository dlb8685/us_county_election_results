import pandas as pd
import sqlite3

if __name__ == '__main__':
	## Connect to the sqlite database where tables have been built.
	con = sqlite3.connect("us_county_election_results.db")
	
	## Save two final tables to a csv file.
	print("Saving final__county_election_data_by_year to csv")
	df = pd.read_sql(sql="select * from final__county_election_data_by_year", con=con)
	df.to_csv("data/final/county_election_data_by_year.csv", index=False)
	del df

	print("Saving final__county_election_data_overall to csv")	
	df = pd.read_sql(sql="select * from final__county_election_data_overall", con=con)
	df.to_csv("data/final/county_election_data_overall.csv", index=False)
	del df
