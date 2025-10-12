# Set a color scale that will be used across different chart types, defined once, here.
"""
CUSTOM_RED_BLUE_COLOR_SCALE=[
    [0.00, "rgb(128,0,0)"],    # blowout Republican win, deep red
    [0.15, "rgb(192,64,64)"],
    [0.30, "rgb(255,96,96)"],
    [0.45, "rgb(255,192,192)"],  # narrow Republican win, light pink
    [0.50, "rgb(192,192,255)"], # narrow Democratic win, light blue
    [0.55, "rgb(96,96,255)"],
    [0.70, "rgb(64,64,192)"],
    [0.85, "rgb(0,0,128)"],  # blowout Democratic win, deep blue
    [1.00, "rgb(0,0,128)"]
]
"""

# These two lists should line up in terms of number of elements.
# They control the shading of counties based on the margin of victory.
DEMOCRATIC_SHARE_BINS = [
    0, 0.20, 0.30, 0.40, 0.45, 0.475, 0.495,
    0.500,
    0.505, 0.525, 0.55, 0.60, 0.70, 0.85, 1.00
]
WINNING_MARGIN_LABELS = [
    "Rep > 60%", "Rep 40–60%", "Rep 20–40%", "Rep 10-20%", "Rep 5-10%", "Rep < 5%", "Rep < 1%",
    "Dem < 1%", "Dem < 5%", "Dem 5–10%", "Dem 10–20%", "Dem 20-40%", "Dem 40-60%", "Dem > 60%"
]
CUSTOM_RED_BLUE_COLOR_SCALE = {
    "Rep > 60%": "rgb(128,0,0)",
    "Rep 40–60%": "rgb(192,64,64)",
    "Rep 20–40%": "rgb(192,96,96)",
    "Rep 10-20%": "rgb(255,96,96)",
    "Rep 5-10%": "rgb(255,128,128)",
    "Rep < 5%": "rgb(255,192,192)",
    "Rep < 1%": "rgb(255,226,226)",
    "Dem < 1%": "rgb(226,226,255)",
    "Dem < 5%": "rgb(192,192,255)",
    "Dem 5–10%": "rgb(128,128,255)",
    "Dem 10–20%": "rgb(96,96,255)",
    "Dem 20-40%": "rgb(96,96,192)",
    "Dem 40-60%": "rgb(64,64,192)",
    "Dem > 60%": "rgb(0,0,128)"
}


# This will help the map zoom in nicely on each state, by default.
# Just needed a one-time create script for this.
STATE_MAP_PARAMS = {
    "All":              {"scope": "usa", "center": {"lat": 37.8, "lon": -96.0}, "projection_scale": 0.88},
    "Alabama":          {"scope": "usa", "center": {"lat": 32.0, "lon": -86.8}, "projection_scale": 4.3},
    "Alaska":           {"scope": "usa", "center": {"lat": 63.7, "lon": -152.5}, "projection_scale": 1.3},
    "Arizona":          {"scope": "usa", "center": {"lat": 33.5, "lon": -111.7}, "projection_scale": 3.3},
    "Arkansas":         {"scope": "usa", "center": {"lat": 34.0, "lon": -92.4}, "projection_scale": 4.2},
    "California":       {"scope": "usa", "center": {"lat": 36.2, "lon": -119.5}, "projection_scale": 2.0},
    "Colorado":         {"scope": "usa", "center": {"lat": 38.2, "lon": -105.5}, "projection_scale": 3.8},
    "Connecticut":      {"scope": "usa", "center": {"lat": 40.8, "lon": -72.7}, "projection_scale": 8.5},
    "Delaware":         {"scope": "usa", "center": {"lat": 38.3, "lon": -75.5}, "projection_scale": 8.2},
    "Florida":          {"scope": "usa", "center": {"lat": 27.0, "lon": -82.0}, "projection_scale": 3.0},
    "Georgia":          {"scope": "usa", "center": {"lat": 31.9, "lon": -83.3}, "projection_scale": 4.2},
    "Hawaii":           {"scope": "usa", "center": {"lat": 19.9, "lon": -156.4}, "projection_scale": 5.5},
    "Idaho":            {"scope": "usa", "center": {"lat": 43.5, "lon": -114.6}, "projection_scale": 3.0},
    "Illinois":         {"scope": "usa", "center": {"lat": 39.3, "lon": -89.3}, "projection_scale": 4.1},
    "Indiana":          {"scope": "usa", "center": {"lat": 39.1, "lon": -86.3}, "projection_scale": 4.9},
    "Iowa":             {"scope": "usa", "center": {"lat": 41.2, "lon": -93.4}, "projection_scale": 5.2},
    "Kansas":           {"scope": "usa", "center": {"lat": 37.7, "lon": -98.3}, "projection_scale": 4.2},
    "Kentucky":         {"scope": "usa", "center": {"lat": 36.8, "lon": -85.2}, "projection_scale": 4.6},
    "Louisiana":        {"scope": "usa", "center": {"lat": 30.4, "lon": -92.4}, "projection_scale": 4.9},
    "Maine":            {"scope": "usa", "center": {"lat": 44.4, "lon": -69.0}, "projection_scale": 4.3},
    "Maryland":         {"scope": "usa", "center": {"lat": 38.2, "lon": -76.7}, "projection_scale": 6.0},
    "Massachusetts":    {"scope": "usa", "center": {"lat": 41.5, "lon": -71.8}, "projection_scale": 7.5},
    "Michigan":         {"scope": "usa", "center": {"lat": 43.3, "lon": -85.4}, "projection_scale": 3.4},
    "Minnesota":        {"scope": "usa", "center": {"lat": 45.5, "lon": -94.3}, "projection_scale": 3.5},
    "Mississippi":      {"scope": "usa", "center": {"lat": 32.1, "lon": -89.7}, "projection_scale": 4.4},
    "Missouri":         {"scope": "usa", "center": {"lat": 37.6, "lon": -92.5}, "projection_scale": 4.4},
    "Montana":          {"scope": "usa", "center": {"lat": 46.2, "lon": -110.0}, "projection_scale": 3.0},
    "Nebraska":         {"scope": "usa", "center": {"lat": 40.8, "lon": -99.6}, "projection_scale": 4.3},
    "Nevada":           {"scope": "usa", "center": {"lat": 38.5, "lon": -116.6}, "projection_scale": 3.2},
    "New Hampshire":    {"scope": "usa", "center": {"lat": 43.3, "lon": -71.6}, "projection_scale": 7.4},
    "New Jersey":       {"scope": "usa", "center": {"lat": 39.5, "lon": -74.7}, "projection_scale": 6.8},
    "New Mexico":       {"scope": "usa", "center": {"lat": 33.5, "lon": -106.0}, "projection_scale": 3.6},
    "New York":         {"scope": "usa", "center": {"lat": 42.1, "lon": -75.5}, "projection_scale": 3.9},
    "North Carolina":   {"scope": "usa", "center": {"lat": 34.7, "lon": -79.8}, "projection_scale": 4.3},
    "North Dakota":     {"scope": "usa", "center": {"lat": 46.7, "lon": -100.5}, "projection_scale": 3.8},
    "Ohio":             {"scope": "usa", "center": {"lat": 39.5, "lon": -82.8}, "projection_scale": 4.5},
    "Oklahoma":         {"scope": "usa", "center": {"lat": 34.8, "lon": -97.5}, "projection_scale": 4.0},
    "Oregon":           {"scope": "usa", "center": {"lat": 43.1, "lon": -120.5}, "projection_scale": 3.5},
    "Pennsylvania":     {"scope": "usa", "center": {"lat": 40.1, "lon": -77.9}, "projection_scale": 4.2},
    "Rhode Island":     {"scope": "usa", "center": {"lat": 40.9, "lon": -71.6}, "projection_scale": 9.0},
    "South Carolina":   {"scope": "usa", "center": {"lat": 33.0, "lon": -80.9}, "projection_scale": 4.5},
    "South Dakota":     {"scope": "usa", "center": {"lat": 43.4, "lon": -100.0}, "projection_scale": 4.2},
    "Tennessee":        {"scope": "usa", "center": {"lat": 35.1, "lon": -86.6}, "projection_scale": 4.4},
    "Texas":            {"scope": "usa", "center": {"lat": 30.2, "lon": -99.3}, "projection_scale": 2.1},
    "Utah":             {"scope": "usa", "center": {"lat": 38.5, "lon": -111.7}, "projection_scale": 3.4},
    "Vermont":          {"scope": "usa", "center": {"lat": 43.3, "lon": -72.7}, "projection_scale": 7.4},
    "Virginia":         {"scope": "usa", "center": {"lat": 37.0, "lon": -78.5}, "projection_scale": 4.4},
    "Washington":       {"scope": "usa", "center": {"lat": 46.6, "lon": -120.7}, "projection_scale": 3.8},
    "West Virginia":    {"scope": "usa", "center": {"lat": 37.8, "lon": -80.6}, "projection_scale": 4.8},
    "Wisconsin":        {"scope": "usa", "center": {"lat": 43.7, "lon": -89.9}, "projection_scale": 4.0},
    "Wyoming":          {"scope": "usa", "center": {"lat": 42.3, "lon": -107.5}, "projection_scale": 3.6}
}
