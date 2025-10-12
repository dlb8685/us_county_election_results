import dash
from dash import html, dcc
import pandas as pd
import plotly.express as px

# Register the page with Dash Pages
dash.register_page(__name__, name="2024 Nationwide Map", path="/nationwide-2024")

# ---- Load data ----
df = pd.read_csv(
    "../data/final/county_election_data_by_year.csv",
    # Prevent pandas from converting strings back to numbers and dropping leading 0's, adding .0, etc.
    dtype={'county_fips': str, 'code': str}
)

# Filter for the year 2024
df_2024 = df[df["year"] == 2024].copy()

# Ensure we have a proper FIPS column as 5-digit strings
df_2024["county_fips"] = df_2024["county_fips"].astype(str).str.zfill(5)

# ---- Create figure ----
fig = px.choropleth(
    df_2024,
    geojson="https://raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json",
    locations="county_fips",
    color="votes_pct_two_party_democrat",
    color_continuous_scale=["red", "purple", "blue"],  # Republican to Democrat
    range_color=(0.15, 0.85),
    scope="usa",
    hover_name="county_name",
    hover_data={
        "county_fips": False,
        "state_abbr": True,
        "county_seat": True,
        "population_total": True,
        "votes_democrat": True,
        "votes_republican": True,
        "votes_other": True,
        "votes_pct_two_party_democrat": ":.1%"
    },
    labels={"votes_pct_two_party_democrat": "Democratic % (two-party share)"}
)

fig.update_layout(
    title_text="2024 U.S. Presidential Election by County",
    title_x=0.5,
    margin={"r":0,"t":40,"l":0,"b":0}
)

# ---- Page layout ----
layout = html.Div([
    html.H2("2024 Nationwide County Map"),
    html.P("Counties shaded by Democratic two-party vote share."),
    dcc.Graph(figure=fig)
])
