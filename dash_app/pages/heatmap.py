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

# ---- Defaults ----
default_color = "margin_bin"
default_size = "votes_total"

layout = html.Div([
    html.H3("County Heatmap (Categorical Discrete Colors)"),

    html.Div([
        html.Div([
            html.Label("State"),
            dcc.Dropdown(
                id="state-dropdown",
                options=([{"label": "All States", "value": "ALL"}] +
                         [{"label": s, "value": s} for s in sorted(df["state_name"].unique())]),
                value="ALL",
                clearable=False
            )
        ], style={"width": "30%", "display": "inline-block"}),

        html.Div([
            html.Label("Year"),
            dcc.Dropdown(
                id="year-dropdown",
                options=[{"label": str(y), "value": y} for y in sorted(df["year"].unique())],
                value=max(df["year"]),
                clearable=False
            )
        ], style={"width": "30%", "display": "inline-block"}),

        html.Div([
            html.Label("Color by"),
            dcc.Dropdown(
                id="color-dim",
                options=[{"label": c, "value": c} for c in df.columns],
                value=default_color,
                clearable=False
            )
        ], style={"width": "30%", "display": "inline-block"}),
    ], style={"marginBottom": "20px"}),

    dcc.Graph(id="heatmap-squarify")
])


@dash.callback(
    Output("heatmap-squarify", "figure"),
    [Input("state-dropdown", "value"),
     Input("year-dropdown", "value"),
     Input("color-dim", "value")]
)
def update_heatmap(state, year, color_dim):
    dff = df[df["year"] == year].copy()
    if state != "ALL":
        dff = dff[dff["state_name"] == state]

    size_dim = default_size
    dff = dff.dropna(subset=[color_dim, size_dim])
    dff = dff.sort_values(size_dim, ascending=False).head(200)

    # Compute squarified layout
    normed = dff[size_dim] / dff[size_dim].sum()
    rects = squarify.squarify(normed, 0, 0, 100, 100)

    # If categorical (like margin_bin), use discrete color map
    color_values = dff[color_dim].astype(str)
    discrete_map = cfg.CUSTOM_RED_BLUE_COLOR_SCALE
    color_order = cfg.WINNING_MARGIN_LABELS

    fig = go.Figure()

    # Draw one rectangle per county
    for i, r in enumerate(rects):
        name = (
            dff["county_name"].iloc[i]
            if "county_name" in dff.columns
            else dff["county_fips"].iloc[i]
        )
        cat = color_values.iloc[i]
        fill_color = discrete_map.get(cat, "#cccccc")  # fallback color
        fig.add_shape(
            type="rect",
            xref="x", yref="y",
            x0=r["x"], y0=r["y"], x1=r["x"]+r["dx"], y1=r["y"]+r["dy"],
            line=dict(width=1, color="white"),
            fillcolor=fill_color,
            layer="above"
        )
        fig.add_trace(go.Scatter(
            x=[None], y=[None],
            mode="markers",
            marker=dict(size=0.1, color=fill_color),
            hovertemplate=(
                f"<b>{name}</b><br>"
                f"{size_dim}: {dff[size_dim].iloc[i]:,}<br>"
                f"{color_dim}: {cat}<extra></extra>"
            ),
            showlegend=False
        ))

    # Build a manual legend from your color mapping
    legend_items = [
        go.Scatter(
            x=[None], y=[None],
            mode="markers",
            marker=dict(size=10, color=discrete_map[label]),
            legendgroup=label,
            showlegend=True,
            name=label
        )
        for label in color_order if label in discrete_map
    ]
    for item in legend_items:
        fig.add_trace(item)

    fig.update_layout(
        xaxis=dict(visible=False),
        yaxis=dict(visible=False, scaleanchor="x", scaleratio=1),
        plot_bgcolor="white",
        margin=dict(l=20, r=20, t=60, b=20),
        title=f"{year} — {state if state!='ALL' else 'All States'} (Colored by {color_dim}, Sized by {size_dim})",
        width=900, height=700,
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=-0.05,
            xanchor="center",
            x=0.5
        )
    )

    return fig