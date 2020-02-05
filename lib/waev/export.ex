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
    end

    defmodule File do
      defstruct filename: nil, available: nil

      def path(e_id, filename) do
        path = "#{Waev.Export.export_path(e_id)}/media/#{filename}"

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
            {nil, %File{filename: filename, available: File.path(e.id, filename) != :error}}

          nil ->
            {text, nil}
        end

      %Message{side: side, date: datetime, text: text, attachment: attachment}
    end
  end

  defstruct id: nil, left: nil, right: nil, messages: []

  def path do
    Application.fetch_env!(:waev, __MODULE__)[:exports_path]
  end

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
          File.stream!("#{export_path(e_id)}/chat.txt")
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

  def export_path(e_id), do: "#{path()}/#{e_id}"

  defp exists?(e_id) do
    e_path = export_path(e_id)

    File.dir?(e_path) && File.regular?("#{e_path}/chat.txt")
  end
end
