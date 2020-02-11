defmodule WaevWeb.ExportsView do
  use WaevWeb, :view

  def party_peek(assigns, party) do
    ~E"""
<div class="party-peek">
  <figure>
    <%= party_avatar(assigns, party, :big) %>
    <figcaption><%= party.name %></figcaption>
  </figure>
</div>
"""
  end

  def party_avatar(assigns, party, size) do
    modifier =
      case size do
        :tiny -> "avatar--tiny"
        :big -> "avatar--big"
      end
    ~E"""
<img class="avatar <%= modifier %>" src="<%= Routes.exports_path(@conn, :get_avatar, @id, party.name) %>" />
"""
  end

  def highlight_urls(nil), do: ""
  def highlight_urls(text) do
    url_re = ~r/https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/

    url_re
    |> Regex.scan(text)
    |> Enum.reduce(text, fn [url|_], t ->
      String.replace(t, url, "<a target=\"_blank\" href=#{url}>#{url}</a>", global: false)
    |> raw()
    end)
  end
end
