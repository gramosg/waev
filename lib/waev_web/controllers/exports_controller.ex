defmodule WaevWeb.ExportsController do
  use WaevWeb, :controller

  def show(conn, %{"id" => id} = params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    size = Map.get(params, "size", "100") |> String.to_integer()

    case Waev.Export.get(id, page, size) do
      {:ok, export} ->
        render(conn, "show.html", id: id, export: export, page: page, size: size)

      :error ->
        conn
        |> put_status(:not_found)
        |> put_view(WaevWeb.ErrorView)
        |> render("404.html")
    end
  end

  def get_media(conn, %{"id" => id, "at_id" => at_id}) do
    case Waev.Export.Message.File.media_path(id, at_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(WaevWeb.ErrorView)
        |> render("404.html")

      path ->
        send_download(conn, {:file, path}, filename: at_id)
    end
  end

  def get_avatar(conn, %{"id" => id, "av_id" => av_id}) do
    case Waev.Export.Party.avatar_path(id, av_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(WaevWeb.ErrorView)
        |> render("404.html")

      path ->
        send_download(conn, {:file, path}, filename: av_id)
    end
  end
end
