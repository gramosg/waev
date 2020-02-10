defmodule Waev.Export do
  require Logger

  defmodule Party do
    defstruct name: nil

    def avatar_path(e_id, filename) do
      path = "#{Waev.Export.export_path(e_id)}/avatars/#{filename}"
      if File.regular?(path), do: path, else: nil
    end

    def new(name) do
      %Party{name: name}
    end
  end

  defmodule Message do
    defmodule File do
      # type is either :image or :file
      defstruct filename: nil, type: nil

      def media_path(e_id, filename) do
        path = "#{Waev.Export.export_path(e_id)}/media/#{filename}"
        if Elixir.File.regular?(path), do: path, else: nil
      end

      def is_image?(filename) do
        valid_extensions = ["png", "jpeg", "jpg"]
        extension = filename |> String.split(".") |> Enum.at(-1) |> String.downcase()
        Enum.member?(valid_extensions, extension)
      end

      def new(filename) do
        type = if is_image?(filename), do: :image, else: :file
        %File{filename: filename, type: type}
      end
    end

    defstruct side: nil, date: nil, text: nil, attachment: nil

    def parse(side, datetime, text) do
      {text, attachment} =
        case Regex.run(~r/([[:ascii:]]+) \(archivo adjunto\)$/u, text) do
          [_, filename] ->
            {nil, File.new(filename)}

          nil ->
            {text, nil}
        end

      IO.puts("Attachment: #{inspect(attachment)}")
      %Message{side: side, date: datetime, text: text, attachment: attachment}
    end
  end

  defstruct id: nil, left: nil, right: nil, messages: []

  def list do
    case File.ls(path()) do
      {:error, _reason} ->
        []

      {:ok, elems} ->
        Enum.filter(elems, &exists?/1)
    end
  end

  def get(e_id) do
    case exists?(e_id) do
      true ->
        e =
          File.stream!(chat_path(e_id))
          |> Enum.take(600)
          |> Enum.reduce(%Waev.Export{id: e_id}, fn line, e ->
            line = String.trim(line)

            case Regex.run(~r/^(\d+\/\d+\/\d+ \d+:\d+) - ([^:]+): (.*)$/u, line) do
              # Match: new message
              [^line, datetime, name, text] ->
                {e, side} =
                  case {e.left, e.right, name} do
                    {nil, _, _} ->
                      {%{e | left: Party.new(name)}, :left}

                    {%{name: left}, _, left} ->
                      {e, :left}

                    {_, nil, _} ->
                      {%{e | right: Party.new(name)}, :right}

                    {_, %{name: right}, right} ->
                      {e, :right}

                    {left, right, name} ->
                      Logger.error(
                        "Found a third party!? (left, right, name) = #{
                          inspect({left.name, right.name, name})
                        }"
                      )

                      {e, nil}
                  end

                message = Message.parse(side, datetime, text)

                %{e | messages: [message | e.messages]}

              # Otherwise: text continuing from the previous one. We need to
              # append it to the last message.
              nil ->
                case e.messages do
                  [first | rest] ->
                    text =
                      case first.text do
                        nil -> line
                        _ -> "#{first.text}\n#{line}"
                      end

                    first = %{first | text: text}
                    %{e | messages: [first | rest]}

                  # ... unless we are before the first message. Drop it.
                  _ ->
                    e
                end
            end
          end)

        {:ok, e}

      false ->
        :error
    end
  end

  def path, do: Application.fetch_env!(:waev, __MODULE__)[:exports_path]
  def export_path(e_id), do: "#{path()}/#{e_id}"
  def chat_path(e_id), do: "#{export_path(e_id)}/chat.txt"

  defp exists?(e_id) do
    File.dir?(export_path(e_id)) && File.regular?(chat_path(e_id))
  end
end
