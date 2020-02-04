defmodule WaevWeb.ExportsController do
  use WaevWeb, :controller

  def show(conn, %{"id" => id}) do
    render(conn, "show.html", id: id)
  end
end
