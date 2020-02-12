defmodule WaevWeb.ExportsView do
  use WaevWeb, :view

  defp consolidate_block({side, messages}), do: {side, Enum.reverse(messages)}

  defp consolidate_day({datestr, blocks}) do
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

    date = "#{d} de #{m} de #{y}"
    {date, Enum.reverse(blocks)}
  end

  # Organize messages to make them easier to display
  # [Waev.Export.Message] -> [{Date, [{Side, [Waev.Export.Message]}]}]
  # Naming:                  ^-Days  ^-Blocks^-Block
  def process_messages(messages) do
    messages
    |> Enum.reduce([], fn message, days ->
      [datestr, timestr] = String.split(message.date, " ")
      side = message.side

      case days do
        # Insert message on the last block (same date, same side)
        [{^datestr, [{^side, block} | old_blocks]} | old_days] ->
          [{datestr, [{side, [message | block]} | old_blocks]} | old_days]

        # Insert message on new block (same date)
        # Old block must be reversed to keep messages in the correct order
        [{^datestr, [{old_side, old_block} | old_blocks]} | old_days] ->
          [
            {datestr, [{side, [message]}, consolidate_block({old_side, old_block}) | old_blocks]}
            | old_days
          ]

        # Insert message on new date
        # Old blocks must be reversed to keep days in the correct order
        [{old_datestr, old_blocks} | old_days] ->
          [{datestr, [{side, [message]}]}, consolidate_day({old_datestr, old_blocks}) | old_days]

        # Ez.
        [] ->
          [{datestr, [{side, [message]}]}]
      end
    end)
    |> Enum.reverse()
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

  def pagination_bar(assigns, page, size) do
    prev = if page == 0, do: 0, else: page - 1
    # TODO max
    next = page + 1

    ~E"""
    <div>
    <a href="<%= Routes.exports_path(@conn, :show, @id, page: prev, size: size) %>">Left</a>
    <a href="<%= Routes.exports_path(@conn, :show, @id, page: next, size: size) %>">Right</a>
    </div>
    """
  end
end
