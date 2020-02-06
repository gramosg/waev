defmodule Waev.Export do
  require Logger

  defmodule Party do
    defstruct name: nil, photo: nil

    def lookup(name) do
      %Party{name: name, photo: nil}
    end
  end

  defmodule Message do
    defmodule Photo do
      defstruct filename: nil, mime: nil, blob: nil

      def valid_extension?(filename) do
        valid_extensions = ["png", "jpeg", "jpg"]
        extension =
          filename |> String.split(".") |> Enum.at(-1) |> String.downcase()
        Enum.member?(valid_extensions, extension)
      end
    end

    defmodule File do
      defstruct filename: nil, available: nil

      def exists?(e_id, filename) do
        Elixir.File.regular?(Waev.Export.media_path(e_id, filename))
      end
      def path(e_id, filename) do
        path = Waev.Export.media_path(e_id, filename)

        if Elixir.File.regular?(path) do
          {:ok, path}
        else
          :error
        end
      end
    end

    defstruct side: nil, date: nil, text: nil, attachment: nil

    def parse(e, side, datetime, text) do
      {text, attachment} =
        case Regex.run(~r/([[:ascii:]]+) \(archivo adjunto\)$/u, text) do
          [_, filename] ->
            available = File.path(e.id, filename) != :error
            # IO.puts("filename: #{filename}, av: #{available}, ve: #{}")
            if available and Message.Photo.valid_extension?(filename) do
              case Elixir.File.read(Waev.Export.media_path(e.id, filename)) do
                {:ok, binary} ->
                  # TODO review mime
                  {nil, %Photo{filename: filename, mime: "image", blob: Base.encode64(binary)}}
                {:error, reason} ->
                  Logger.error("Error opening photo #{filename}: #{reason}")
                  {nil, %File{filename: filename, available: false}}
              end
            else
              {nil, %File{filename: filename, available: available}}
            end

          nil ->
            {text, nil}
        end

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
          |> Enum.take(200)
          |> Enum.reduce(%Waev.Export{id: e_id}, fn line, e ->
            line = String.trim(line)

            case Regex.run(~r/^(\d+\/\d+\/\d+ \d+:\d+) - ([^:]+): (.*)$/u, line) do
              # Match: new message
              [^line, datetime, name, text] ->
                {e, side} =
                  case {e.left, e.right, name} do
                    {nil, _, _} ->
                      {%{e | left: Party.lookup(name)}, :left}

                    {%{name: left}, _, left} ->
                      {e, :left}

                    {_, nil, _} ->
                      {%{e | right: Party.lookup(name)}, :right}

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

                message = Message.parse(e, side, datetime, text)

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
  def media_path(e_id, media_id), do: "#{export_path(e_id)}/media/#{media_id}"

  defp exists?(e_id) do
    File.dir?(export_path(e_id)) && File.regular?(chat_path(e_id))
  end
end
