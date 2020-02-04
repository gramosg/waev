defmodule WaevWeb.ExportsController do
  use WaevWeb, :controller

  def show(conn, %{"id" => id}) do
    case Waev.Export.get(id) do
      {:ok, export} ->
        render(conn, "show.html", id: id, export: export)

      :error ->
        conn
        |> put_status(:not_found)
        |> put_view(WaevWeb.ErrorView)
        |> render("404.html")
    end
  end
end
