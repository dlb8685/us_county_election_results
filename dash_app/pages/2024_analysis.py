import dash
from dash import html

dash.register_page(__name__, name="2024 Analysis", path="/2024-analysis")

layout = html.Div([
    html.H2("2024 Analysis", style={"textAlign": "center"}),
    html.P('Going into the 2024 Presidential Election, <a href="https://www.bbc.com/news/articles/c511pyn3xw3o">seven states</a> were expected to be decisive. Joe Biden had defeated Donald Trump in six of the seven in 2020, and based on all polling and recent results, they were the only states likely to be "up for grabs" in 2024. These states were: Pennsylvania, Michigan, and Wisconsin in the Midwest, Georgia and North Carolina in the South, and Nevada and Arizona in the West.')
)

