defmodule Waev.Export do
  def path do
    Application.fetch_env!(:waev, __MODULE__)[:exports_path]
  end

  def list do
    case File.ls(path()) do
      {:error, _reason} -> []
      {:ok, elems} -> Enum.filter(elems, &File.dir?/1)
    end
  end
end
