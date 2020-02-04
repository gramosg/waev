defmodule Waev.Export do
  defmodule Party do
    defstruct name: nil, photo: nil
  end

  defmodule Message do
    defmodule Photo do
      defstruct filename: nil, mime: nil, blob: nil
    end

    defmodule File do
      defstruct filename: nil
    end

    defstruct party: nil, date: nil, text: nil, attachment: nil
  end

  defstruct left: nil, right: nil, messages: []

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

  def get(e) do
    case exists?(e) do
      true ->
        export =
          File.stream!("#{path()}/#{e}/chat.txt")
          |> Enum.reduce(%Waev.Export{}, fn line, export ->
            line = String.trim(line)

            case Regex.run(~r/^(\d+\/\d+\/\d+ \d+:\d+) - ([^:]+): (.*)$/u, line) do
              # Match: new message
              [^line, datetime, name, text] ->
                party = nil

                message =
                  case Regex.run(~r/^([^ ]+) \(archivo adjunto\)$/u, text) do
                    [^text, filename] ->
                      %Message{party: party, date: datetime, text: nil, attachment: filename}

                    nil ->
                      %Message{party: party, date: datetime, text: text, attachment: nil}
                  end

                %{export | messages: [message | export.messages]}

              # Otherwise: text continuing from the previous one. We need to
              # append it to the last message.
              nil ->
                case export.messages do
                  [first | rest] ->
                    text =
                      case first.text do
                        nil -> line
                        _ -> "#{first.text}\n#{line}"
                      end

                    first = %{first | text: text}
                    %{export | messages: [first | rest]}

                  # ... unless we are before the first message. Drop it.
                  _ ->
                    export
                end
            end
        end)

        {:ok, export}

      false ->
        :error
    end
  end

  defp exists?(e) do
    e_path = "#{path()}/#{e}"

    File.dir?(e_path) && File.regular?("#{e_path}/chat.txt")
  end
end
