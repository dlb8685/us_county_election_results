import dash
from dash import html, dcc

app = dash.Dash(
    __name__,
    use_pages=True,            # enables multipage support
    suppress_callback_exceptions=True,
    external_stylesheets=["https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css"]
)

app.layout = html.Div([
    html.H1("US County Election Results Dashboard", className="text-center mt-3"),

    html.Div([
        dcc.Link(page["name"], href=page["path"], className="btn btn-outline-primary mx-1")
        for page in dash.page_registry.values()
    ], className="text-center mb-4"),

    dash.page_container            # this is where the active page renders
])

server = app.server

if __name__ == "__main__":
    app.run(debug=True)
