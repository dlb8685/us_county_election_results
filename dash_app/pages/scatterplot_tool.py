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

    dcc.Graph(id="scatterplot")
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
        Input("filter-val", "value")
    ]
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
        title=f"{y_col} vs {x_col}"
    )
    fig.update_layout(margin=dict(l=40, r=40, t=60, b=40))
    return fig