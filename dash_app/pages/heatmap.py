import dash
from dash import html, dcc, Input, Output
import pandas as pd
import numpy as np
import plotly.graph_objects as go
import squarify
import county_results_utils as cutils
import county_results_config as cfg  # bring in your custom color scale

dash.register_page(__name__, name="County Heatmap", path="/heatmap")

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
default_color = "margin_bin"
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
                value=max(df["year"]),
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

    dcc.Graph(id="heatmap-squarify")
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

    size_dim = default_size
    dff = dff.dropna(subset=[selected_color_by, size_dim])
    dff = dff.sort_values(size_dim, ascending=False).head(200)

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

        # tiny invisible point just to provide hover (no legend)
        fig.add_trace(go.Scatter(
            x=[r["x"] + r["dx"]/2],
            y=[r["y"] + r["dy"]/2],
            mode="markers",
            marker=dict(size=max(r["dx"], r["dy"]) * 5, opacity=0, color=fill_color),
            hovertemplate=(
                f"<b>{name}</b><br>"
                f"{size_dim}: {dff[size_dim].iloc[i]:,}<br>"
                f"{selected_color_by}: {cat}<extra></extra>"
            ),
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
        margin=dict(l=20, r=20, t=60, b=20),
        title=f"{year} — {state if state!='ALL' else 'All States'} (Colored by {selected_color_by}, Sized by {size_dim})",
        width=900, height=700,
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