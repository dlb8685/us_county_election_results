import dash
from dash import html, dcc, Input, Output
import pandas as pd
import plotly.express as px
from collections import defaultdict
import county_results_config as cfg

# Register page
dash.register_page(__name__, name="Scatterplot Explorer", path="/scatterplot")

# Load data once
df = pd.read_csv(
    "../data/final/county_election_data_overall.csv",
    dtype={"county_fips": str}
)

# Group columns by category (for cleaner drop-down)
# Also load human-friendly readable names.
grouped = defaultdict(list)
for col, meta in cfg.COLUMN_MAP_OVERALL.items():
    if col in df.columns:
        grouped[meta.get("group", "Other")].append(
            {"label": meta.get("label", col), "value": col}
        )

# We need a flat structure where the group is incorporated directly into each option.
# FIXME: Make this play nice with dcc.Dropdown when having Group (Demographics, Economics) included.
dropdown_options = [
    {"label": group, "options": sorted(opts, key=lambda x: x["label"])}
    for group, opts in grouped.items()
]
flattened_dropdown_options = [
    {"label": opt["label"], "value": opt["value"]}
    for group_block in dropdown_options
    for group, opts in [(group_block["label"], group_block["options"])]
    for opt in opts
]

# ---- Layout ----
layout = html.Div([
    html.H3("County Election Scatterplot"),

    html.Div([
        html.Div([
            html.Label("X-axis"),
            dcc.Dropdown(
                id="x-axis",
                options=flattened_dropdown_options,
                value="votes_pct_democrat_2020"
            )
        ], style={"width": "19%", "display": "inline-block", "marginRight": "1%"}),

        html.Div([
            html.Label("Y-axis"),
            dcc.Dropdown(
                id="y-axis",
                options=flattened_dropdown_options,
                value="votes_pct_democrat_2024"
            )
        ], style={"width": "19%", "display": "inline-block", "marginRight": "1%"}),

        html.Div([
            html.Label("Color by"),
            dcc.Dropdown(
                id="color-dim",
                options=flattened_dropdown_options,
                value=None,
                placeholder="Optional"
            )
        ], style={"width": "19%", "display": "inline-block", "marginRight": "1%"}),

        html.Div([
            html.Label("Size by"),
            dcc.Dropdown(
                id="size-dim",
                options=flattened_dropdown_options,
                value=None,
                placeholder="Optional"
            )
        ], style={"width": "19%", "display": "inline-block", "marginRight": "1%"}),

        # State filter dropdown
        # For now, only filter on State.
        html.Div([
            html.Label("Select state"),
            dcc.Dropdown(
                id="state-filter",
                options=[{"label": "All", "value": "All"}] +
                        [{"label": s, "value": s} for s in sorted(df["state_name"].dropna().unique())],
                value="All"
            )
        ], style={"width": "19%", "display": "inline-block"})

    ]),

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


# ---- Main scatterplot callback ----
@dash.callback(
    Output("scatterplot", "figure"),
    [
        Input("x-axis", "value"),
        Input("y-axis", "value"),
        Input("color-dim", "value"),
        Input("size-dim", "value"),
        Input("state-filter", "value"),
    ],
)
def update_scatter(x_col, y_col, color_col, size_col, state_filter):
    # Create a hard copy of our main data frame which can be modified without touching the original.
    # i.e. filtering out certain states, etc.
    dff = df.copy()
    if state_filter != "All":
        dff = dff[dff["state_name"] == state_filter]

    # Use the mapping config to get the human-name and range for each column.
    display_x = cfg.COLUMN_MAP_OVERALL.get(x_col, {}).get("label", x_col)
    display_y = cfg.COLUMN_MAP_OVERALL.get(y_col, {}).get("label", y_col)
    # apply scale if defined.
    # Mainly to make the axes on 0-1 pct dimensions show the full 0-1 range.
    x_min = cfg.COLUMN_MAP_OVERALL.get(x_col, {}).get("min")
    x_max = cfg.COLUMN_MAP_OVERALL.get(x_col, {}).get("max")
    y_min = cfg.COLUMN_MAP_OVERALL.get(y_col, {}).get("min")
    y_max = cfg.COLUMN_MAP_OVERALL.get(y_col, {}).get("max")

    fig = px.scatter(
        dff,
        x=x_col,
        y=y_col,
        color=color_col if color_col else None,
        size=size_col if size_col else None,
        hover_name="county_fips" if "county_fips" in dff.columns else None,
        title=f"{display_x} by {display_y}",
    )

    # Keep the plot area square *by size*, not by units.
    # (No scaleanchor/scaleratio — that’s what was blowing up your 0–1 axes.)
    PLOT  = 700          # desired plot area (NOT the whole figure)
    L, R, T, B = 60, 360, 60, 60   # leave hard space on the right for colorbar
    fig.update_layout(
        height=PLOT + T + B,
        width=PLOT + L + R,  # make it square on screen
        margin=dict(l=L, r=R, t=T, b=B),
        plot_bgcolor="#f9f9f9",
        paper_bgcolor="#ffffff",
    )

    # Tight bounds without Plotly adding padding
    fig.update_xaxes(range=[x_min, x_max])
    fig.update_yaxes(range=[y_min, y_max])

    # Always show a faint diagonal from lower-left to upper-right *in paper coords*
    # so it spans the square regardless of axis scales.
    fig.add_shape(
        type="line",
        x0=0, y0=0, x1=1, y1=1,
        xref="paper", yref="paper",
        line=dict(color="gray", width=1, dash="dash"),
        layer="below",
    )
    
    # Update the layout to position the legend outside
    # --- lock plot area to 750x750 and park colorbar in the right margin ---
    #PLOT  = 700          # desired plot area (NOT the whole figure)
    #L, R, T, B = 60, 300, 60, 60   # leave hard space on the right for colorbar
    #fig.update_layout(
    #    width=PLOT + L + R,              # total figure width
    #    height=PLOT + T + B,             # total figure height
    #    margin=dict(l=L, r=R, t=T, b=B), # FIXED margins
    #)

    # show/hide the colorbar and push it into the reserved right margin
    fig.update_layout(coloraxis_showscale=bool(color_col))
    if color_col:
        fig.update_layout(
            coloraxis_colorbar=dict(
                title=color_col,
                xanchor="left",
                x=7,        # >1 pushes it outside the plot into the right margin
                y=0.5,
                len=0.85,
                thickness=16,
                outlinewidth=0,
            )
        )

    return fig