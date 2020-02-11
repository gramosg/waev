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
end
