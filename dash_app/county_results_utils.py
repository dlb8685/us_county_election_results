import pandas as pd
import county_results_config as cfg

def bin_counties_by_margin(votes_pct_two_party_democrat):
    # This returns a margin label tied to a color
    margin_bin = pd.cut(
        votes_pct_two_party_democrat, bins=cfg.DEMOCRATIC_SHARE_BINS, labels=cfg.WINNING_MARGIN_LABELS, include_lowest=True
    )
    return margin_bin
