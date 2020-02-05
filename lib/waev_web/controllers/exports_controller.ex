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

  def get_attachment(conn, %{"id" => id, "at_id" => at_id}) do
    case Waev.Export.Message.File.path(id, at_id) do
      {:ok, path} ->
        send_download(conn, {:file, path}, filename: at_id)

      :error ->
        conn
        |> put_status(:not_found)
        |> put_view(WaevWeb.ErrorView)
        |> render("404.html")
    end
  end
end
