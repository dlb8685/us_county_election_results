import dash
from dash import html

dash.register_page(__name__, name="Using this Tool", path="/", order=4)

layout = html.Div([
    html.P("Explore county election data across different visualizations."),
    html.H2("Visualization Types", style={"textAlign": "center"}),
    # Heatmap section
    html.H3("Heatmap"),
    html.P("This visualization type displays all of the counties for a given state in a grid. They are sized by the number of votes cast, so that it is immediately apparent how much each country contributes to the overall vote total for a state. Below is an example for Georgia in 2024."),
    html.Img(
        src="/assets/heatmap_2024_georgia_margin_in_votes.png",
        style={"width": "80%", "display": "block", "margin-left": "2%"}
    ),
    html.P("You may also hover over a specific block to show more information about that county."),
    html.Img(
        src="/assets/heatmap_2024_georgia_hover_example.png",
        style={"width": "20%", "display": "block", "margin": "0 auto"}
    ),
    # Nationwide Map section
    html.H3("Natonwide Map"),
    html.P("This is a nationwide map of all counties. By default it is shaded to show the margin of victory in each county in 2024, but there are a lot of toggles to adjust it. It is possible to show only a specific state. It is possible to toggle between different elections, going back to 2000. Or the shading can be altered to show absolute margin of victory (in votes), 'swing' in the margin of victory from the previous election, or also to show demographic data such as population, income, and education."),
    html.P("This map can be used to look for interesting trends. For example, if you look at the next two graphs, you can see that the areas in which Republicans are most dominant on a pure percentage basis, often winning by 60% of the vote or more, do not actually help them out the most, in terms of winning raw votes."),
    html.Img(
        src="/assets/nationwide_map_2024_margin_of_victory.png",
        style={"width": "80%", "display": "block", "margin-left": "2%"}
    ),
    html.P("The second map shows that many of the Republicans' biggest wins in terms of raw votes, often come in suburban and exurban counties where they are 'only' winning by 10 or 20% in terms of the margin, but the number of votes in the county is much larger. Areas to focus on include suburban Dallas, or Macomb County, Michigan which gave Trump his single largest vote margin in Michigan, in spite of him only winning the county by 13%."),
    html.Img(
        src="/assets/nationwide_map_2024_margin_of_victory_votes.png",
        style={"width": "80%", "display": "block", "margin-left": "2%"}
    ),
    html.Img(
        src="/assets/nationwide_map_2024_michigan_margin_of_victory_votes.png",
        style={"width": "80%", "display": "block", "margin-left": "2%", "margin-top": "2%"}
    ),
    # Scatterplot Explorer section
    html.H3("Scatterplot Explorer"),
    html.P("This is a scatterplot of counties, which can be used to find relationships between voting performance and other attributes. By default it compares 2020 to 2024 results, with more Hispanic counties shaded more darkly. Counties above the dotted line voted more Democratic in 2024 than in 2020, and vice versa. Not surprisingly, most counties are below the line. But even within this group, there are some clear clusters showing that heavily Hispanic counties tended to have larger movement towards Republicans and away from Democrats between 2020-24."),
    html.Img(
        src="/assets/scatterplot_2024_vote_swing_by_hispanic.png",
        style={"width": "80%", "display": "block", "margin-left": "2%", "margin-top": "2%"}
    ),
    # Conclusion
    html.H3("Conclusion"),
    html.P("These are just some very brief examples of how the tools on this site can be used. Separately, there is a much more extensive look at the 2024 election with some analysis of why the results turned out the way they did, especially in comparison to 2020."),
], style={"margin-left": "3%", "margin-right": "3%"}
)
