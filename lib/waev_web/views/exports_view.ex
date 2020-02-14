defmodule WaevWeb.ExportsView do
  use WaevWeb, :view

  defp pp_date(datestr) do
    # TODO use timex to pretty-print dates (translations??)
    [d, m, y] = String.split(datestr, "/") |> Enum.map(&String.to_integer/1)
    y = 2000 + y

    m =
      Enum.at(
        [
          "enero",
          "febrero",
          "marzo",
          "abril",
          "mayo",
          "junio",
          "julio",
          "agosto",
          "septiembre",
          "octubre",
          "noviembre",
          "diciembre"
        ],
        m - 1
      )

    "#{d} de #{m} de #{y}"
  end

  # Organize messages to make them easier to display
  # [Waev.Export.Message] -> [{Date, [{Side, [Waev.Export.Message]}]}]
  # Naming:                  ^-Days  ^-Blocks^-Block
  def process_messages(messages) do
    messages
    |> Enum.reduce([], fn message, days ->
      [datestr, _timestr] = String.split(message.date, " ")
      side = message.side

      case days do
        # Insert message on the last block (same date, same side)
        [{^datestr, [{^side, block} | old_blocks]} | old_days] ->
          [{datestr, [{side, [message | block]} | old_blocks]} | old_days]

        # Insert message on new block (same date)
        # Old block must be reversed to keep messages in the correct order
        [{^datestr, [{old_side, old_block} | old_blocks]} | old_days] ->
          [
            {datestr, [{side, [message]}, {old_side, old_block} | old_blocks]}
            | old_days
          ]

        # Insert message on new date
        # Old blocks must be reversed to keep days in the correct order
        [{old_datestr, old_blocks} | old_days] ->
          [{datestr, [{side, [message]}]}, {old_datestr, old_blocks} | old_days]

        # Ez.
        [] ->
          [{datestr, [{side, [message]}]}]
      end
    end)
    # Reverse messages, blocks and days, as they were appended in the list head
    # Enum.reduce is used to avoid double iteration with map + reverse
    |> Enum.reduce([], fn {date, blocks}, days ->
      blocks =
        Enum.reduce(blocks, [], fn {side, messages}, blocks ->
          [{side, Enum.reverse(messages)} | blocks]
        end)

      # Reverse days
      [{pp_date(date), blocks} | days]
    end)
  end

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
    url_re =
      ~r/https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/

    url_re
    |> Regex.scan(text)
    |> Enum.reduce(text, fn [url | _], t ->
      t
      |> String.replace(url, "<a target=\"_blank\" href=#{url}>#{url}</a>", global: false)
    end)
  end

  def nl_to_br(text) do
    String.replace(text, "\n", "<br />")
  end

  def pagination_bar(assigns, %{page: page, size: size, pages: pages}) do
    offset = 1 # How many buttons to see in each side
    path = fn page ->
      ~E"""
      <%= Routes.exports_path(@conn, :show, @id, page: page, size: size) %>
      """
    end

    btn = fn enabled, highlight, page, text ->
      ~E"""
      <a class="button button-large button-colored <%= if (not highlight) do %>button-clear<% else %>button-milligram-solid<% end %>"
         <%= if enabled do %>
           href="<%= path.(page) %>"
         <% else %>
           disabled
         <% end %>>
        <%= text %>
      </a>
      """
    end

    ~E"""
    <div class="row row-center row--padded">
      <%= btn.(page != 1, false, page-1, raw("<i class=\"fas fa-caret-left\"></i>")) %>
      <%= if (page > 1 + offset) do %>
        <%= btn.(true, false, 1, "1") %>
      <% end %>
      <%= if (page > 1 + offset + 1) do %>
        ...
      <% end %>
      <%= for p <- max(1, page-offset) .. min(pages, page+offset) do %>
        <%= if (p == page) do %>
          <%= btn.(false, true, page, page) %>
        <% else %>
          <%= btn.(p != page, false, p, p) %>
        <% end %>
      <% end %>
      <%= if (page < pages - offset - 1) do %>
        ...
      <% end %>
      <%= if (page < pages - offset) do %>
        <%= btn.(true, false, pages, pages) %>
      <% end %>
      <%= btn.(page != pages, false, page+1, raw("<i class=\"fas fa-caret-right\"></i>")) %>
    </div>
    """
  end
end
