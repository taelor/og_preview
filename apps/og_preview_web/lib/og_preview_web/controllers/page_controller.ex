defmodule OgPreviewWeb.PageController do
  use OgPreviewWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
