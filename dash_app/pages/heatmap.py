import dash
from dash import html, dcc, Input, Output
import pandas as pd
import numpy as np
import plotly.graph_objects as go
import squarify
import county_results_utils as cutils
import county_results_config as cfg  # bring in your custom color scale

dash.register_page(__name__, name="County Heatmap", path="/heatmap", order=3)

# ---- Load data ----
df = pd.read_csv(
    "../data/final/county_election_data_by_year.csv",
    dtype={"county_fips": str, "code": str}
)
df["margin_bin"] = cutils.bin_counties_by_margin(df["votes_pct_two_party_democrat"])
df["swing_bin"] = cutils.bin_counties_by_swing(df["votes_pct_swing_from_prev_election"])
df["winning_margin_in_votes_bin"] = cutils.bin_counties_by_margin_in_votes(
    df["votes_democrat"] - df["votes_republican"]
)
df["winning_margin_in_votes_abs"] = abs(df["votes_democrat"] - df["votes_republican"])

# Extract options for color dropdown
available_years = sorted(df["year"].unique())
available_states = ["All"] + sorted(df["state_name"].unique())
# Only give 3 options for coloring the heatmap.
# Heatmap does not handle continuous spectrums as well for whatever reason.
# Could probably debug, but for a v1 let's use these 3 which are the most important.
available_colors = [
    {"label": "Margin of Victory (%)", "value": "margin_bin"},
    {"label": "Swing from Prior Election (%)", "value": "swing_bin"},
    {"label": "Margin of Victory (in Votes)", "value": "winning_margin_in_votes_bin"}
]

# ---- Defaults ----
default_color = "winning_margin_in_votes_bin"
default_size = "votes_total"

layout = html.Div([
    html.H3("County Heatmap (Categorical Discrete Colors)", style={"text-align": "center"}),

    html.Div([
        html.Div([
            html.Label("State"),
            dcc.Dropdown(
                id="state-dropdown",
                options=([{"label": s, "value": s} for s in sorted(df["state_name"].unique())]),
                value="Alabama",
                clearable=False
            )
        ], style={"width": "30%", "display": "inline-block", "margin-left": "1%", "margin-right": "1%"}),

        html.Div([
            html.Label("Year"),
            dcc.Dropdown(
                id="year-dropdown",
                options=[{"label": str(y), "value": y} for y in sorted(df["year"].unique())],
                value=2024,
                clearable=False
            )
        ], style={"width": "30%", "display": "inline-block", "margin-right": "1%"}),

        html.Div([
            html.Label("Color by"),
            dcc.Dropdown(
                id="color-dim",
                options=[{"label": c["label"], "value": c["value"]} for c in available_colors],
                value=default_color,
                clearable=False
            )
        ], style={"width": "30%", "display": "inline-block", "margin-right": "1%"}),
    ], style={"marginBottom": "20px"}),

    dcc.Graph(id="heatmap-squarify"),
    
    # Summary table
    html.Div(id="heatmap-summary-table", style={"margin-top": "30px"})
])


@dash.callback(
    Output("heatmap-squarify", "figure"),
    [Input("state-dropdown", "value"),
     Input("year-dropdown", "value"),
     Input("color-dim", "value")]
)
def update_heatmap(state, year, selected_color_by):
    dff = df[df["year"] == year].copy()
    if state != "ALL":
        dff = dff[dff["state_name"] == state]

    # Calculate margin in votes (positive = Democrat won, negative = Republican won)
    dff["margin_in_votes"] = dff["votes_democrat"] - dff["votes_republican"]
    
    # Size by absolute margin in votes
    size_dim = "winning_margin_in_votes_abs"
    
    dff = dff.dropna(subset=[selected_color_by, size_dim])
    
    # Sort by margin_in_votes: largest Democrat wins first (most positive), 
    # down to largest Republican wins last (most negative)
    # This makes them meet in the middle
    dff = dff.sort_values("margin_in_votes", ascending=False).head(200)

    # --- squarify expects sizes that sum to width*height ---
    W, H = 100, 100
    sizes = dff[size_dim].astype(float).clip(lower=1e-9).to_list()
    normed = squarify.normalize_sizes(sizes, W, H)
    rects = squarify.squarify(normed, 0, 0, W, H)  # list of dicts with x,y,dx,dy

    color_values = dff[selected_color_by].astype(str)
    
    # Based on the variable entered, create a color scheme
    if selected_color_by == "margin_bin":
        discrete_map = cfg.MARGIN_RED_BLUE_COLOR_SCALE
        color_order = cfg.MARGIN_LABELS
        available_color_label_text = "Margin of Victory (%)"
    elif selected_color_by == "swing_bin":
        discrete_map = cfg.SWING_RED_BLUE_COLOR_SCALE
        color_order = cfg.SWING_LABELS
        available_color_label_text = "Swing from Prior Election (%)"
    elif selected_color_by == "winning_margin_in_votes_bin":
        discrete_map = cfg.WINNING_MARGIN_VOTES_RED_BLUE_COLOR_SCALE
        color_order = cfg.WINNING_MARGIN_VOTES_LABELS
        available_color_label_text = "Margin of Victory (in Votes)"

    fig = go.Figure()

    # --- draw non-overlapping rectangles ---
    for i, r in enumerate(rects):
        name = dff["county_name"].iloc[i] if "county_name" in dff.columns else dff["county_fips"].iloc[i]
        cat = color_values.iloc[i]
        fill_color = discrete_map.get(cat, "#cccccc")

        fig.add_shape(
            type="rect",
            xref="x", yref="y",
            x0=r["x"], y0=r["y"],
            x1=r["x"] + r["dx"], y1=r["y"] + r["dy"],
            line=dict(width=1, color="white"),
            fillcolor=fill_color,
            layer="above"
        )

        # Generate the hover text for each rectangle.
        county_name = dff["county_name"].iloc[i]
        state_abbr = dff["state_abbr"].iloc[i]
        county_seat = dff["county_seat"].iloc[i] if "county_seat" in dff.columns else "—"
        votes_total = dff["votes_total"].iloc[i]
        votes_pct_democrat = dff["votes_pct_democrat"].iloc[i]
        votes_pct_republican = dff["votes_pct_republican"].iloc[i]
        margin_in_votes = dff["margin_in_votes"].iloc[i]
        population_pct_white = dff["population_pct_white"].iloc[i]
        population_pct_black = dff["population_pct_black"].iloc[i]
        population_pct_hispanic = dff["population_pct_hispanic"].iloc[i]
        median_household_income_2010 = dff["median_household_income_2010"].iloc[i]
        poverty_pct_overall_2010 = dff["poverty_pct_overall_2010"].iloc[i]
        bachelor_degree_pct_of_adults = dff["bachelor_degree_pct_of_adults"].iloc[i]
        
        # Format the margin nicely
        if margin_in_votes > 0:
            margin_text = f"D +{margin_in_votes:,.0f}"
        else:
            margin_text = f"R +{abs(margin_in_votes):,.0f}"
        
        hover_text = (
            f"<b>County:</b> {county_name}, {state_abbr}<br>"
            f"<b>County Seat:</b> {county_seat}<br><br>"
            f"<b>Total Votes:</b> {votes_total:,}<br>"
            f"<b>Vote % (Democrat):</b> {votes_pct_democrat:.1%}<br>"
            f"<b>Vote % (Republican):</b> {votes_pct_republican:.1%}<br>"
            f"<b>Raw Vote Margin:</b> {margin_text}<br><br>"
            f"<b>% of Population (White):</b> {population_pct_white:.1%}<br>"
            f"<b>% of Population (Black):</b> {population_pct_black:.1%}<br>"
            f"<b>% of Population (Hispanic):</b> {population_pct_hispanic:.1%}<br><br>"
            f"<b>Income (Median Household, 2010):</b> ${median_household_income_2010:,.0f}<br>"
            f"<b>Poverty Rate (Overall, 2010):</b> {poverty_pct_overall_2010:.1%}<br>"
            f"<b>Bachelor's Degree (% of Adults):</b> {bachelor_degree_pct_of_adults:.1%}<extra></extra>"
        )
        fig.add_trace(go.Scatter(
            x=[r["x"] + r["dx"]/2],
            y=[r["y"] + r["dy"]/2],
            mode="markers",
            marker=dict(size=max(r["dx"], r["dy"]) * 3, opacity=0, color=fill_color),
            hovertemplate=hover_text,
            showlegend=False
        ))

    # --- manual legend for your discrete bins ---
    for label in [lbl for lbl in color_order if lbl in discrete_map]:
        fig.add_trace(go.Scatter(
            x=[None], y=[None],
            mode="markers",
            marker=dict(size=10, color=discrete_map[label]),
            name=label,
            showlegend=True
        ))

    # --- critical: fix the axis ranges to match the 0..100 layout ---
    fig.update_xaxes(range=[0, W], visible=False, fixedrange=True)
    fig.update_yaxes(range=[H, 0], visible=False, fixedrange=True)  # top-left origin

    fig.update_layout(
        plot_bgcolor="white",
        margin=dict(l=450, r=20, t=60, b=20),
        title=f"{year} — {state if state!='ALL' else 'All States'} (Colored by {available_color_label_text}, Sized by Margin in Votes, Sorted Dem→Rep)",
        width=1350, height=700,
        legend=dict(
            # vertical legend
            orientation="v",
            yanchor="top",
            y=1,
            xanchor="left",
            # just outside the plot area
            x=1.02
        )
    )
    return fig


@dash.callback(
    Output("heatmap-summary-table", "children"),
    Input("state-dropdown", "value"),
    Input("year-dropdown", "value")
)
def update_summary_table(state, year):
    """Display state-level summary table for the heatmap"""
    if state is None or year is None:
        return None
    
    # Calculate summary using utility function
    summary = cutils.calculate_state_summary(df, state, year)
    if summary is None:
        return None
    
    # Create table using utility function
    table = cutils.create_state_summary_table(summary)
    
    # Wrap in container using utility function
    return cutils.create_state_summary_container([table])
