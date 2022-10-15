defmodule OgPreviewWeb.PageControllerTest do
  use OgPreviewWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "<h1>OG Preview</h1>"
  end
end
