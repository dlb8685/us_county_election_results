import pandas as pd
import county_results_config as cfg

def bin_counties_by_margin(votes_pct_two_party_democrat):
    # This returns a margin label tied to a color
    margin_bin = pd.cut(
        votes_pct_two_party_democrat, bins=cfg.MARGIN_BINS, labels=cfg.MARGIN_LABELS, include_lowest=True
    )
    return margin_bin

def bin_counties_by_margin_in_votes(winning_margin_in_votes):
    # This returns a margin label tied to a color
    winning_margin_in_votes_bin = pd.cut(
        winning_margin_in_votes, bins=cfg.WINNING_MARGIN_VOTES_BINS, labels=cfg.WINNING_MARGIN_VOTES_LABELS, include_lowest=True
    )
    return winning_margin_in_votes_bin


def bin_counties_by_swing(votes_pct_swing_from_prev_election):
    # This returns a margin label tied to a color
    swing_bin = pd.cut(
        votes_pct_swing_from_prev_election, bins=cfg.SWING_BINS, labels=cfg.SWING_LABELS, include_lowest=True
    )
    return swing_bin

# Utils to create a results table for a given state at the bottom of a map.
def calculate_state_summary(df, state_name, year):
    """
    Calculate state-level vote totals for a given state and year.
    
    Args:
        df: DataFrame with county-level election data
        state_name: Name of the state (e.g., "Kentucky")
        year: Election year (e.g., 2024)
    
    Returns:
        Dictionary with vote totals, percentages, winner, and margin
        Returns None if no data found
    """
    # Filter data for this state and year
    state_data = df[(df["state_name"] == state_name) & (df["year"] == year)]
    
    if len(state_data) == 0:
        return None
    
    # Sum up votes across all counties
    total_dem = state_data["votes_democrat"].sum()
    total_rep = state_data["votes_republican"].sum()
    total_other = state_data["votes_other"].sum()
    total_votes = total_dem + total_rep + total_other
    
    # Calculate percentages
    pct_dem = (total_dem / total_votes * 100) if total_votes > 0 else 0
    pct_rep = (total_rep / total_votes * 100) if total_votes > 0 else 0
    pct_other = (total_other / total_votes * 100) if total_votes > 0 else 0
    
    # Determine winner
    if total_dem > total_rep:
        winner = "Democrat"
        margin = pct_dem - pct_rep
    else:
        winner = "Republican"
        margin = pct_rep - pct_dem
    
    return {
        "state": state_name,
        "year": year,
        "votes_democrat": total_dem,
        "votes_republican": total_rep,
        "votes_other": total_other,
        "votes_total": total_votes,
        "pct_democrat": pct_dem,
        "pct_republican": pct_rep,
        "pct_other": pct_other,
        "winner": winner,
        "margin": margin
    }


def create_state_summary_table(summary_data):
    """
    Create an HTML table from state summary data.
    
    Args:
        summary_data: Dictionary from calculate_state_summary()
    
    Returns:
        Dash HTML component with styled table
    """
    if summary_data is None:
        return None
    
    # Create table data ordered by winner
    if summary_data["winner"] == "Democrat":
        table_data = [
            {"Party": "Democrat", "Votes": f"{summary_data['votes_democrat']:,}", 
             "Percentage": f"{summary_data['pct_democrat']:.2f}%"},
            {"Party": "Republican", "Votes": f"{summary_data['votes_republican']:,}", 
             "Percentage": f"{summary_data['pct_republican']:.2f}%"},
            {"Party": "Other", "Votes": f"{summary_data['votes_other']:,}", 
             "Percentage": f"{summary_data['pct_other']:.2f}%"}
        ]
    else:
        table_data = [
            {"Party": "Republican", "Votes": f"{summary_data['votes_republican']:,}", 
             "Percentage": f"{summary_data['pct_republican']:.2f}%"},
            {"Party": "Democrat", "Votes": f"{summary_data['votes_democrat']:,}", 
             "Percentage": f"{summary_data['pct_democrat']:.2f}%"},
            {"Party": "Other", "Votes": f"{summary_data['votes_other']:,}", 
             "Percentage": f"{summary_data['pct_other']:.2f}%"}
        ]
    
    # Create styled table
    return html.Div([
        html.H5(f"{summary_data['year']} Results - {summary_data['state']}", 
               style={"text-align": "center", "margin-bottom": "10px"}),
        html.Table([
            html.Thead(
                html.Tr([
                    html.Th("Party", style={"padding": "10px", "text-align": "left", "border-bottom": "2px solid #ddd"}),
                    html.Th("Votes", style={"padding": "10px", "text-align": "right", "border-bottom": "2px solid #ddd"}),
                    html.Th("Percentage", style={"padding": "10px", "text-align": "right", "border-bottom": "2px solid #ddd"})
                ])
            ),
            html.Tbody([
                html.Tr([
                    html.Td(row["Party"], style={"padding": "8px", "text-align": "left", 
                                                 "font-weight": "bold" if i == 0 else "normal"}),
                    html.Td(row["Votes"], style={"padding": "8px", "text-align": "right"}),
                    html.Td(row["Percentage"], style={"padding": "8px", "text-align": "right"})
                ]) for i, row in enumerate(table_data)
            ])
        ], style={"margin": "0 auto", "border-collapse": "collapse", "width": "400px",
                 "box-shadow": "0 2px 4px rgba(0,0,0,0.1)"}),
        html.P(f"Margin: {summary_data['margin']:.2f}%", 
              style={"text-align": "center", "margin-top": "10px", "font-style": "italic", "color": "#666"})
    ], style={"display": "inline-block", "vertical-align": "top", "margin": "0 20px"})


def create_state_summary_container(tables):
    """
    Create a container for one or more state summary tables.
    
    Args:
        tables: List of HTML table components from create_state_summary_table()
    
    Returns:
        Dash HTML component with centered container
    """
    if not tables or len(tables) == 0:
        return None
    
    return html.Div(tables, style={"text-align": "center", "padding": "20px", 
                                   "background-color": "#f8f9fa", "border-radius": "8px",
                                   "margin": "0 auto", "max-width": "1000px"})

