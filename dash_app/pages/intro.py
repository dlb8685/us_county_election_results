import dash
from dash import html

dash.register_page(__name__, path="/")

layout = html.Div([
    html.H2("Welcome to the Dashboard"),
    html.P("Explore county election data across different visualizations.")
])
