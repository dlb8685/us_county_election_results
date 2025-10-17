import dash
from dash import html, dcc, Input, Output
import pandas as pd
import plotly.express as px
import county_results_config as cfg
import county_results_utils as cutils

# Register page
dash.register_page(__name__, name="Nationwide Map", path="/nationwide-map")

# ---- Load data once ----
df = pd.read_csv(
    "../data/final/county_election_data_by_year.csv",
    dtype={"county_fips": str, "code": str}
)
df["margin_bin"] = cutils.bin_counties_by_margin(df["votes_pct_two_party_democrat"])


# Extract options for dropdowns
available_years = sorted(df["year"].unique())
available_states = ["All"] + sorted(df["state_name"].unique())

# ---- Layout ----
layout = html.Div([
    html.H2("U.S. Presidential Election Results by County"),
    html.P("Counties shaded by Democratic two-party vote share."),
    
    html.Div([
        html.Label("Select Year:"),
        dcc.Dropdown(
            id="year-dropdown",
            options=[{"label": str(y), "value": y} for y in available_years],
            value=2024,
            clearable=False,
            style={"width": "200px"}
        ),
        html.Label("Select State:"),
        dcc.Dropdown(
            id="state-dropdown",
            options=[{"label": s, "value": s} for s in available_states],
            value="All",
            clearable=False,
            style={"width": "250px"}
        ),
    ], style={"display": "flex", "gap": "20px", "marginBottom": "20px"}),

    dcc.Graph(id="county-map", style={"height": "85vh"})
])


# ---- Callback ----
@dash.callback(
    Output("county-map", "figure"),
    Input("year-dropdown", "value"),
    Input("state-dropdown", "value")
)
def update_map(selected_year, selected_state):
    dff = df[df["year"] == selected_year].copy()
    
    # Filter for state if selected
    if selected_state != "All":
        dff = dff[dff["state_name"] == selected_state]
        scope = None
    else:
        scope = "usa"

    fig = px.choropleth(
        dff,
        geojson="https://raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json",
        locations="county_fips",
        color="margin_bin",  # categorical variable
        color_discrete_map=cfg.CUSTOM_RED_BLUE_COLOR_SCALE,
        category_orders={"margin_bin": cfg.WINNING_MARGIN_LABELS},  # keep order consistent in legend
        scope=scope,
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

    # If zooming to a specific state, tighten the view
    if selected_state != "All":
        fig.update_layout(title_text=f"{selected_year} Election – {selected_state}")
        # This config will center the map based on which state is selected.
        center_map_params = cfg.STATE_MAP_PARAMS.get(selected_state, cfg.STATE_MAP_PARAMS["All"])
        fig.update_geos(
            # only apply scope if projection is albers usa
            # A few western states are set to Mercator so they don't slant way offline.
            scope="usa" if center_map_params.get("projection_type", "albers usa") == "albers usa" else None,
            center=center_map_params["center"],
            projection_scale=center_map_params["projection_scale"],
            projection_type=center_map_params.get("projection_type", "albers usa"),
            visible=False
        )
    else:
        fig.update_layout(title_text=f"{selected_year} U.S. Presidential Election by County",
                          geo=dict(scope="usa"))
        # When looking at the full U.S., this zooms out slightly by default so that lower regions aren't cut off.
        center_map_params = cfg.STATE_MAP_PARAMS["All"]
        fig.update_geos(
            scope=center_map_params["scope"],
            center=center_map_params["center"],
            projection_scale=center_map_params["projection_scale"],
            visible=False
        )
    fig.update_layout(
        title_x=0.5,
        margin={"r":0,"t":40,"l":0,"b":0}
    )
        
    return fig