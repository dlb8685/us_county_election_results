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
df["swing_bin"] = cutils.bin_counties_by_swing(df["votes_pct_swing_from_prev_election"])
df["winning_margin_in_votes_bin"] = cutils.bin_counties_by_margin_in_votes(
    df["votes_democrat"] - df["votes_republican"]
)

# Extract options for dropdowns
available_years = sorted(df["year"].unique())
available_states = ["All"] + sorted(df["state_name"].unique())
available_colors = [
    {"label": "Margin of Victory (%)", "value": "margin_bin"},
    {"label": "Swing from Prior Election (%)", "value": "swing_bin"},
    {"label": "Margin of Victory (in Votes)", "value": "winning_margin_in_votes_bin"}
] + cfg.COLUMN_COUNTY_MAP_BY_YEAR


# ---- Layout ----
layout = html.Div([
    html.H3("U.S. Presidential Election Results by County", style={"text-align": "center"}),
    
    html.Div([
        # Year dropdown
        html.Div([
            html.Label("Select Year:"),
            dcc.Dropdown(
                id="year-dropdown",
                options=[{"label": str(y), "value": y} for y in available_years],
                value=2020,
                clearable=False
            )
        ], style={"width": "30%", "display": "inline-block", "margin-left": "1%", "margin-right": "1%"}),
        # State dropdown
        html.Div([
            html.Label("Select State:"),
            dcc.Dropdown(
                id="state-dropdown",
                options=[{"label": s, "value": s} for s in available_states],
                value="All",
                clearable=False,
            )
        ], style={"width": "30%", "display": "inline-block", "margin-right": "1%"}),
        # Color dropdown
        html.Div([
            html.Label("Color By:"),
            dcc.Dropdown(
                id="color-by-dropdown",
                options=[{"label": c["label"], "value": c["value"]} for c in available_colors],
                value="margin_bin",
                clearable=False
            )
        ], style={"width": "30%", "display": "inline-block", "margin-right": "1%"}),
    
    ], style={"display": "flex", "flexWrap": "wrap", "gap": "20px", "marginBottom": "20px"}),

    dcc.Graph(id="county-map", style={"height": "85vh"})
])


# ---- Callback ----
@dash.callback(
    Output("county-map", "figure"),
    Input("year-dropdown", "value"),
    Input("state-dropdown", "value"),
    Input("color-by-dropdown", "value")
)
def update_map(selected_year, selected_state, selected_color_by):
    dff = df[df["year"] == selected_year].copy()
    
    # Filter for state if selected
    if selected_state != "All":
        dff = dff[dff["state_name"] == selected_state]
        scope = None
    else:
        scope = "usa"

    # Index dff properly so that hover overlay will work, later.
    dff = dff.dropna(subset=["county_fips"]).copy()
    dff["county_fips"] = dff["county_fips"].astype(str).str.zfill(5)
    ix = dff.set_index("county_fips")

    # Custom Color By Fields (which use a different palette than the default greenscale)
    if selected_color_by == "margin_bin":
        color_discrete_map=cfg.MARGIN_RED_BLUE_COLOR_SCALE
        category_orders={"margin_bin": cfg.MARGIN_LABELS}  # keep order consistent in legend        
        color_continuous_scale = None
        color_range = None
        available_color_label_text = "Margin of Victory (%)"
    elif selected_color_by == "swing_bin":
        color_discrete_map=cfg.SWING_RED_BLUE_COLOR_SCALE
        category_orders={"swing_bin": cfg.SWING_LABELS}  # keep order consistent in legend
        color_continuous_scale = None
        color_range = None
        available_color_label_text = "Swing from Prior Election (%)"
    elif selected_color_by == "winning_margin_in_votes_bin":
        color_discrete_map=cfg.WINNING_MARGIN_VOTES_RED_BLUE_COLOR_SCALE
        category_orders={"winning_margin_in_votes_bin": cfg.WINNING_MARGIN_VOTES_LABELS}  # keep order consistent in legend
        color_continuous_scale = None
        color_range = None
        available_color_label_text = "Margin of Victory (in Votes)"
    else:
        color_discrete_map = None
        category_orders = None
        color_continuous_scale="algae"
        color_range = cfg.COLOR_RANGE_MAP_BY_YEAR.get(selected_color_by, cfg.COLOR_RANGE_MAP_BY_YEAR["default"])
        available_color_labels = {c["value"]: c["label"] for c in available_colors}
        available_color_label_text = available_color_labels.get(selected_color_by, selected_color_by)
    labels={selected_color_by: available_color_label_text}

    fig = px.choropleth(
        dff,
        geojson="https://raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json",
        locations="county_fips",
        color=selected_color_by,
        color_discrete_map=color_discrete_map,
        category_orders=category_orders,
        color_continuous_scale=color_continuous_scale,
        range_color=color_range,
        scope=scope,
        labels=labels
    )

    
    # Build the hover-box properly
    hover_fields = [
        "county_name", "state_abbr", "county_seat",
        "votes_total", "votes_pct_democrat", "votes_pct_republican",
        "population_pct_white", "population_pct_black", "population_pct_hispanic",
        "median_household_income_2010", "poverty_pct_overall_2010", "bachelor_degree_pct_of_adults"
    ]
    customdata = dff[hover_fields]
    hover_template = (
        "<b>County:</b> %{customdata[0]}, %{customdata[1]}<br>" +
        "<b>County Seat:</b> %{customdata[2]}<br><br>" +
        "<b>Total Votes:</b> %{customdata[3]:,}<br>" +
        "<b>Vote % (Democrat):</b> %{customdata[4]:.1%}<br>" +
        "<b>Vote % (Republican):</b> %{customdata[5]:.1%}<br><br>"
        "<b>% of Population (White):</b> %{customdata[6]:.1%}<br>" +
        "<b>% of Population (Black):</b> %{customdata[7]:.1%}<br>" +
        "<b>% of Population (Hispanic):</b> %{customdata[8]:.1%}<br><br>" +
        "<b>Income (Median Household, 2010):</b> $%{customdata[9]:,}<br>" +
        "<b>Poverty Rate (Overall, 2010):</b> %{customdata[10]:.1%}<br>" +
        "<b>Bachelor's Degree (% of Adults):</b> %{customdata[11]:.1%}" +
        "<extra></extra>"
    )
    # Each group by the map color is one "trace".
    # For each trace we must separately create hovers by FIPS, or else they will be completely misaligned.
    # i.e. every county X will show data for some other county Y
    for tr in fig.data:
        # FIPS for just this trace, in the same order as the trace
        locs = list(tr.locations)
        aligned = ix.loc[locs, hover_fields]
        tr.customdata = aligned.to_numpy()
        # This will actually apply template per trace
        tr.hovertemplate = hover_template


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