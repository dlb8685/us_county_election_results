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
