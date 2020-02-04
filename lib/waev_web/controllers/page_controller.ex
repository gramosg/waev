defmodule WaevWeb.PageController do
  use WaevWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
