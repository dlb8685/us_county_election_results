import dash
from dash import html

dash.register_page(__name__, name="2024 Analysis", path="/2024-analysis")

layout = html.Div([
    html.H2("2024 Analysis", style={"textAlign": "center"}),
    html.P(["Going into the 2024 Presidential Election, ",
        html.A("seven states", href="https://www.bbc.com/news/articles/c511pyn3xw3o", target="_blank", style={"textDecoration": "underline"}),
        " were expected to be decisive. Joe Biden had defeated Donald Trump in six of the seven in 2020, and based on all polling and recent results, they were the only states likely to be 'up for grabs' in 2024. These states were: Pennsylvania, Michigan, and Wisconsin in the Midwest, Georgia and North Carolina in the South, and Nevada and Arizona in the West."]),
    html.P("Many predicted the margins in these states would be razor thin, with each candidate eking out narrow victories in some of them. Fears of a repeat of 2020 or 2000 were common. However, somewhat surprisingly, Donald Trump carried all seven of these states over Kamala Harris en route to an easy victory."),
    html.P("Here, we dig into each of these states, one by one, and compare them to 2020 and earlier. Our goal here is to explain exactly how Trump performed better in 2024 compared to 2020 (and in some cases, even 2016). The tools on this project can be quite illuminative in answering this question."),
    # Pennsylvania
    html.H3("Pennsylvania", style={"textAlign": "center"}),
    html.P(["2020 Results: Biden 3,458,229 (50.0%) -- Trump 3,377,674 (48.8%)",
        html.Br(),
        "2024 Results: Trump 3,543,308 (50.4%) -- Harris 3,423,042 (48.7%)"
        ], style={"text-align": "center"}),
    html.P("Pennsylvania had for many years been a narrow but consistent Democratic win, until 2016 and Trump's rise. In that year, across the state, huge swings towards Trump occurred in many counties, albeit with a counter-trend for the Democrats in a few suburban counties near Philadelphia."),
    html.Img(
        src="/assets/nationwide_map_2016_pennsylvania_swing.png",
        style={"width": "80%", "display": "block", "margin-left": "2%"}
    ),
    html.P("However, in 2020, Biden was able to claw back a lot of ground, particularly in his home region of eastern Pennsylvania. Notably, Philadelphia did not participate in this trend, and while it provided Biden's largest margin of victory by far, he underperformed Hillary Clinton there."),
    html.Img(
        src="/assets/nationwide_map_2020_pennsylvania_swing.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.Img(
        src="/assets/scatterplot_2020_pennsylvania_vote_swing.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%", "margin-top": "1%"}
    ),
    html.P("Compared to most other counties in Pennsylvania (and nationally), Philadelphia saw very small increases in turnout in 2020. As the county/city in Pennsylvania with the largest black population, by far, any slippage in black support for Democrats would likely have an outsized effect here in 2024."),
    html.Img(
        src="/assets/scatterplot_2024_pennsylvania_total_votes_shift.png",
        style={"width": "60%", "display": "block", "margin-left": "2%", "margin-bottom": "2%"}
    ),
    html.P("On the other hand, Democrats in 2020 made huge gains in suburban Philadelphia, and in other large cities like Pittsburgh. In terms of absolute margin of votes, these went from being almost even, to contributing tens of thousands of additional votes to Biden in 2020, vis a vis 2016. If Democrats could continue to build on their gains in these areas, minimize slippage in Philadelphia, they would likely have a clear path to winning Pennsylvania again in 2024."),
    html.P("So what actually happened?"),
    html.P('Firstly, Democrats suffered a "double-whammy" in Philadelphia. Not only did their margin fall from 63% to "only" 59%, but turnout in Philadelphia fell by tens of thousands of votes. Their net win fell from 471 thousand to 424 thousand. Given their 80 thousand vote margin in 2020, Philadelphia alone removed over half of it.'),
    html.P("On the other hand, Harris held up somewhat well in very rural areas of Pennsylvania. While she lost many of these areas by substantial amounts, these were among the few areas in the country where she held even with Biden or had slippage in the 0-1% range. In fact, *every* country in Pennsylvania that swung towards Harris in 2024 was a county that she still lost substantially. This might suggest that Democrats have hit a floor with rural white voters in this region after several cycles of slippage."),
    html.Img(
        src="/assets/nationwide_map_2024_pennsylvania_swing.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.Img(
        src="/assets/nationwide_map_2024_pennsylvania_pct_white.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%", "margin-bottom": "2%"}
    ),
    html.P("This leaves a final, decisive area. Whether it was due to national factors, or his own background, Biden improved substantially on Hillary Clinton's numbers in eastern Pennsylvania, outside of Philadelphia. Harris did not hold onto these gains."),
    html.P('For instance, she lost Bucks County (with a total of 401 thousand votes at stake) after Biden won it by 4 points. That equaled 16 thousand votes that swung towards Trump. She won Montgomery county by "only" 23 points, after Biden won it by 26 (with a total of 520 thousand votes at stake). That was another 15-16 thousand votes that shifted. Add this up with 5-7 other fairly large counties in eastern Pennsylvania, and you have more than enough to explain how Trump went from losing by 80,000 to winning by 120,000 votes.'),
    html.P(["Democrats *did* do relatively well in some other suburban areas, nationally. Unlike some other regions there was not the additional factor of a heavy Hispanic population, a drop in black turnout, or Gaza in play here in Pennsylvania. Thus, it would serve Democrats well to understand why they did not hold onto some of their gains in suburban voters in this region. And vice versa for Trump and Republicans, perhaps there is something in their playbook which worked here that might be applied to other suburban areas where they have seen erosion. Perhaps a deep-dive would show that inflation or housing costs were worse in the ",
        html.A("Philadelphia metro area", href="https://whyy.org/articles/philly-metro-affordability-renters/", target="_blank", style={"textDecoration": "underline"}),
        " than in other places such as Indianpolis or Atlanta. Or perhaps one of the biggest transgender controversies being specifically ",
        html.A("in Pennsylvania", href="https://www.bbc.com/news/articles/cy4yy4dv2dyo", target="_blank", style={"textDecoration": "underline"}),
        " may have been a factor. My data cannot answer these questions, but these are both hypotheses that come to mind."]),
    # Michigan
    html.H3("Michigan", style={"textAlign": "center"}),
    html.P(["2020 Results: Biden 2,804,040 (50.0%) -- Trump 2,649,852 (48.8%)",
        html.Br(),
        "2024 Results: Trump 2,816,636 (50.4%) -- Harris 2,736,533 (48.7%)"
        ], style={"text-align": "center"}),
    html.P("In Michigan, Democrats went from winning by 150 thousand votes to losing by 80 thousand. Here, the cause of defeat for Harris is probably much more straightforward."),
    html.P(["Wayne County, where Detroit is located, swung sharply against Harris. Her net margin in votes fell from 332 to 248 thousand--almost a 100 thousand vote falloff. This alone removed well over 1/2 of the Democrats' margin of victory from 2020. There were two main factors that probably came into play here. One is that this is a heavily black area, and such counties tendedto have pretty flat turnout and slight swings towards Republicans in 2024. Secondly, this does not show up in my data, but it is known that the ",
    html.A("Arab-American vote", href="https://www.aljazeera.com/news/2024/11/6/we-warned-you-arab-americans-in-michigan-tell-kamala-harris", target="_blank", style={"textDecoration": "underline"}),
    " drastically fell off, with turnout down and with Trump gaining substantially among those who did vote."]),
    html.Img(
        src="/assets/nationwide_map_2024_michigan_swing.png",
        style={"width": "60%", "display": "block", "margin-left": "2%"}
    ),
    html.P("However, unlike Pennsylvania, the picture in Michigan is a lot less nuanced--Democrats slipped almost everywhere. Again, their relative strength in suburban areas did not show up in Michigan and Detroit, and in fact in working-class suburban Macomb County, they went from a 40 thousand vote loss in 2020 to a 70 thousand vote loss in 2024. Macomb and Wayne County alone were enough to wipe out Biden's margin of victory in 2020, and the rest of the state was gravy for Trump. As we will see in other states, there are suburban areas where Democrats <em>imporoved</em> in 2024, and others where they fell of a lot. It will be important for both sides to figure out how these suburban areas differ from each other."),
    # Wisconsin
    html.H3("Wisconsin", style={"textAlign": "center"}),
    html.P(["2020 Results: Biden 1,630,866 (50.0%) -- Trump 1,610,184 (48.8%) ",
        html.Br(),
        "2024 Results: Trump 1,697,626 (49.6%) -- Harris 1,668,229 (48.7%)"
        ], style={"text-align": "center"}),
    html.P("Wisconsin was the closest state in the 2024 election."),
    html.P('Unlike in Pennsylvania and Michigan, Trump lost ground in Wisconsin''s main suburban counties, in spite of improving his margin overall. The Milwaukie area is known for having three "WOW" counties which constitute its suburban area. These three counties (Washington, Ozaukee, Waukesha) all swung marginally to Kamala Harris, while the rest of the state moved towards Trump.'),
    html.Img(
        src="/assets/nationwide_map_2024_wisconsin_swing.png",
        style={"width": "60%", "display": "block", "margin-left": "15%"}
    ),
    html.P('One potential problem for Democrats in the long-term is southwestern Wisconsin. This area used to be relatively Democratic, especially for a working-class, 90%+ white region. As recently as 2012, Democrats handily won most of the counties in this region. If these counties continue to vote more like other counties nationally that are demographically similar, they have plenty more room to move to the Republican column. Democrats do not have enough suburban "territory" in Wisconsin to counterbalance that, unless there is a much bigger move towards Democrats in the WOW counties. In 2024, it was likely the significant movement in this area that improved Trump''s overall margin by 50 thousand votes vs. 2020 and allowed him to win the state. Overall this shows that even after three cycles of Trump defining the Republican Party, there are still pockets where his brand of politics has room to improve in future years.'),
    html.Img(
        src="/assets/nationwide_map_2012_wisconsin_results.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.Img(
        src="/assets/nationwide_map_2024_wisconsin_results.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.P('Unlike Philadelphia and Detroit, however, Milwaukee did not show a significant move away from Democrats. This may be because it is a "whiter" city compared to the other two, and Democrats had more problems with heavily Hispanic and to a lesser extent, Black cities. Harris won this county by 39%, while Biden won it by 40%.'),
    # North Carolina
    html.H3("North Carolina", style={"textAlign": "center"}),
    html.P(["2020 Results: Trump 2,758,775 (49.9%) -- Biden 2,684,292 (48.6%)",
        html.Br(),
        "2024 Results: Trump 2,898,423 (50.8%) -- Harris 2,715,375 (47.7%)"
        ], style={"text-align": "center"}),
    html.P("This is the only one of the seven key swing states which Trump won in 2020. Democrats hoped that its suburban character and rapidly increasing population in cities like Charlotte, Durham, etc. would be enough to tip the scales by 1-2 percent in 2024. However, overall results in this state were in line with many other swing states where Democrats lost group by 1-2 percent."),
    html.P("Unlike many other states we've looked at so far, North Carolina has a much higher Black population (along with Georgia) which gives us some good bellwethers for the Black vote. More specifically, these counties are good proxies for lower-income, rural Black voters who have started to, albeit to a much lesser extent, vote more Republican in line with other rural others. We can see that some of the largest swings in North Carolina between 2020 and 2024 happened in rural northeastern areas of the state, including in a few Black-majority counties."),
    html.Img(
        src="/assets/nationwide_map_2024_north_carolina_pct_black.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.Img(
        src="/assets/nationwide_map_2024_north_carolina_swing.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.P("However, this alone was far from enough to increase Trump's margin of victory by almost 100,000 votes from 2020. If we look at the most heavily populated counties, Mecklenberg (Charlotte), Raleigh, and Guilford (Greensboro), they saw slight swings against Harris but only in the 0-2% range, adding up to maybe 10,000 net votes at most."),
    html.P("In general, North Carolina was more of an across the board problem for Democrats, especially in the eastern part of the state, which is less populated, less prosperous, and lower-income. The fact that this is a more more diverse area and less monolithically white, did not help Harris and the Democrats in 2024. While this added up to a marginal change overall, it points to continued erosion that Democrats have seen in lower-income, less educated areas. In 2024, they did not get enough of a gain in suburban areas to counterbalance this."),
    # Georgia
    html.H3("Georgia", style={"textAlign": "center"}),
    html.P(["2020 Results: Biden 2,473,633 (49.5%) -- Trump 2,461,854 (49.2%)",
        html.Br(),
        "2024 Results: Trump 2,663,117 (50.7%) -- Harris 2,548,017 (48.5%)"
        ], style={"text-align": "center"}),
    html.P("Georgia is quite similar to North Carolina demographically, in terms of black/white population and rural-urban divide, though in Georgia this is even more pronounced with the massive Atlanta metropolitan area."),
    html.P("The suburban Atlanta area was one of the few bright spots for Harris, where she did outperform Biden's 2020 results. As one of the faster-growing areas in the country, there were undoubtedly new arrivals between 2020 and 2024 who abetted this trend."),
    html.Img(
        src="/assets/nationwide_map_2024_georgia_swing.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.Img(
        src="/assets/scatterplot_2024_georgia_total_votes_shift.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.P("What undid Harris was the lack of continued gains in the core of Atlanta, which is actually a more diverse area than many of the outlying suburbs, along with signifiant erosion in the southern and eastern parts of the state. Much like in North Carolina's eastern half, which also saw a move against Democrats in 2024, we see here that this area tends to be low population, low income, but is not homogenous ethnically. While we can't prove from these counties alone that the Black vote moved against Harris by some amount, it does fit in with a larger story seen in places like eastern North Carolina, Wayne County, Michigan, and Philadelphia. As presently constituted, the Democratic coaltiion can only win with extremely high support from Black voters, and slippage in areas where they are prevalent must be a serious red flag for the party. Conversely, Republicans could build an almost unbeatable coalation (at least until some other factor intervened) merely by adding another 5-10 points to their totals in heavily Black areas. If this trend from 2024 continues, it could eventually break the relative deadlock we've seen politically over the last 15-25 years."),
    html.Img(
        src="/assets/nationwide_map_2024_georgia_total_votes.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.Img(
        src="/assets/nationwide_map_2024_georgia_pct_white.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.P("One more point before moving on. If we zoom out a bit, we can see a more continuous trend in the southeast, where more Appalachian areas swung less towards Trump in 2024 (albeit, many were already voting 80%+ for him), but coastal areas seem to have more room to move future results, relative to 2020 or 2024. The trend is negative for Democrats, but they are still getting 30% of the vote in many of these places, and thus they have more room for it to get worse in future elections."),
    html.Img(
        src="/assets/nationwide_map_2024_swing_southeast.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.Img(
        src="/assets/nationwide_map_2024_pct_white_southeast.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.P("Perhaps continued gains in suburbia would let the Democrats counter this trend, but in 2024 at least, those gains were marginal. Even in Georgia, where they benefitted much more from this trend, it wasn't enough to hold the state."),
    # Nevada
    html.H3("Nevada", style={"textAlign": "center"}),
    html.P(["2020 Results: Biden 703,486 (50.1%) -- Trump 669,890 (47.7%)",
        html.Br(),
        "2024 Results: Trump 751,205 (50.6%) -- Harris 705,197 (47.5%)"
        ], style={"text-align": "center"}),
    html.P("Nevada is slightly less interesting to look at compared to many states, just because the vast, vast majority of its vote comes from a single county: Clark County, where Las Vegas is located."),
    html.P("Clark County not only has a large Hispanic population, but it also has a significant Black population and one of the larger Asian populations in the country. In 2020, Biden won 53.7% of the vote in this county. In 2024, Kamala Harris won 50.4%. Even with a narrow, 1-point win in the Reno area, it is effectively impossible for Democrats to win Nevada if they are tied in the Las Vegas metro area, as Republicans dominate what few other votes are scattered in the state."),
    html.Img(
        src="/assets/nationwide_map_2024_nevada_swing.png",
        style={"width": "60%", "display": "block", "margin-left": "15%"}
    ),
    html.P("I will keep Nevada fairly brief, just because Arizona has very similar dynamics. But Trump winning this state was exhibit A in the success of his Latino and minority strategy. Conversely, if Democrats do not figure out their issues with the Hispanic vote, they have a long, long way for further erosion to take place. If this trned  continues, Nevada and Arizona may go out of play in future years and New Mexico could quickly become a swing state again."),
    html.Img(
        src="/assets/nationwide_map_2024_pct_hispanic_southwest.png",
        style={"width": "60%", "display": "block", "margin-left": "15%"}
    ),
    # Arizona
    html.H3("Arizona", style={"textAlign": "center"}),
    html.P(["2020 Results: Biden 2,473,633 (49.5%) -- Trump 2,461,854 (49.2%)",
        html.Br(),
        "2024 Results: Trump 2,663,117 (50.7%) -- Harris 2,548,017 (48.5%)"
        ], style={"text-align": "center"}),
    html.P("Finally, we come to Arizona. In this state too, much like Nevada, a huge part of the vote comes from a single county. In this case, Maricopa County with the Phoenix metro area. This county swung significantly against Harris in 2024 after Biden's victory in 2020. In 2020, Biden won 50.3% of the vote in Maricopa County. In 2024, Harris won 47.7%."),
    html.Img(
        src="/assets/nationwide_map_2024_arizona_results.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.Img(
        src="/assets/nationwide_map_2024_arizona_swing.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.P("Every county in Arizona swung against the Democrats and towards Trump in 2024. The south of the state is significantly Hispanic and saw movement towards Trump across the board. In the northeast, there are some American Indian majority counties which also heavily broke against the Democrats. While these areas don't have huge populations, they do have tens of thousands of voters, and losing 5-10% of margin there did not help Harris in a close state where Biden won by a mere 12 thousand votes."),
    html.Img(
        src="/assets/nationwide_map_2024_arizona_pct_hispanic.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
    html.Img(
        src="/assets/nationwide_map_2024_arizona_pct_am_ind.png",
        style={"width": "45%", "display": "inline", "margin-left": "2%"}
    ),
], style={"margin-left": "3%", "margin-right": "3%"}
)

