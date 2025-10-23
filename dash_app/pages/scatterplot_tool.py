import dash
from dash import html, dcc, Input, Output
import pandas as pd
import plotly.express as px

# Register page
dash.register_page(__name__, name="Scatterplot Explorer", path="/scatterplot")

# ---- Load data once ----
df = pd.read_csv(
    "../data/final/county_election_data_overall.csv",
    dtype={"county_fips": str}
)

# ---- Layout ----
layout = html.Div([
    html.H3("County Election Scatterplot"),

    html.Div([
        html.Div([
            html.Label("X-axis"),
            dcc.Dropdown(
                id="x-axis",
                options=[{"label": col, "value": col} for col in df.columns],
                value=df.columns[0]
            )
        ], style={"width": "19%", "display": "inline-block"}),

        html.Div([
            html.Label("Y-axis"),
            dcc.Dropdown(
                id="y-axis",
                options=[{"label": col, "value": col} for col in df.columns],
                value=df.columns[1]
            )
        ], style={"width": "19%", "display": "inline-block"}),

        html.Div([
            html.Label("Color by"),
            dcc.Dropdown(
                id="color-dim",
                options=[{"label": col, "value": col} for col in df.columns],
                value=None,
                placeholder="Optional"
            )
        ], style={"width": "19%", "display": "inline-block"}),

        html.Div([
            html.Label("Size by"),
            dcc.Dropdown(
                id="size-dim",
                options=[{"label": col, "value": col} for col in df.columns],
                value=None,
                placeholder="Optional"
            )
        ], style={"width": "19%", "display": "inline-block"}),

        html.Div([
            html.Label("Filter column"),
            dcc.Dropdown(
                id="filter-col",
                options=[{"label": col, "value": col} for col in df.columns],
                value=None,
                placeholder="Optional"
            )
        ], style={"width": "19%", "display": "inline-block"}),

        html.Div([
            html.Label("Filter value"),
            dcc.Dropdown(id="filter-val", placeholder="Select a value")
        ], style={"width": "19%", "display": "inline-block", "marginTop": "10px"}),
    ], style={"marginBottom": "20px"}),

    # Generate the graph and center it in the screen.
    html.Div(
        dcc.Graph(id="scatterplot"),
        style={
            "display": "flex",
            "justifyContent": "center",
            "alignItems": "center",  # optional: vertical centering
            "width": "100%",
        },
    )
])

# ---- Callback for dynamic filter options ----
@dash.callback(
    Output("filter-val", "options"),
    Input("filter-col", "value")
)
def set_filter_values(filter_col):
    if filter_col:
        unique_vals = sorted(df[filter_col].dropna().unique())
        return [{"label": str(v), "value": v} for v in unique_vals]
    return []

# ---- Main scatterplot callback ----
@dash.callback(
    Output("scatterplot", "figure"),
    [
        Input("x-axis", "value"),
        Input("y-axis", "value"),
        Input("color-dim", "value"),
        Input("size-dim", "value"),
        Input("filter-col", "value"),
        Input("filter-val", "value"),
    ],
)
def update_scatter(x_col, y_col, color_col, size_col, filter_col, filter_val):
    dff = df.copy()
    if filter_col and filter_val:
        dff = dff[dff[filter_col] == filter_val]

    fig = px.scatter(
        dff,
        x=x_col,
        y=y_col,
        color=color_col if color_col else None,
        size=size_col if size_col else None,
        hover_name="county_fips" if "county_fips" in dff.columns else None,
        title=f"{y_col} vs {x_col}",
    )

    # Keep the plot area square *by size*, not by units.
    # (No scaleanchor/scaleratio — that’s what was blowing up your 0–1 axes.)
    fig.update_layout(
        height=700,
        width=700,  # make it square on screen
        margin=dict(l=40, r=40, t=60, b=40),
        plot_bgcolor="#f9f9f9",
        paper_bgcolor="#ffffff",
    )

    # Tight bounds without Plotly adding padding
    fig.update_xaxes(constrain="domain")
    fig.update_yaxes(constrain="domain")

    # Always show a faint diagonal from lower-left to upper-right *in paper coords*
    # so it spans the square regardless of axis scales.
    fig.add_shape(
        type="line",
        x0=0, y0=0, x1=1, y1=1,
        xref="paper", yref="paper",
        line=dict(color="gray", width=1, dash="dash"),
        layer="below",
    )

    return fig