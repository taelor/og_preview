defmodule OgPreview.ProcessUrl do
  alias OgPreview.{ExtractOg, Repo, Url}

  import Ecto.Query

  def call(url_string) when is_binary(url_string) do
    # i hate this already, Url, url, url...
    case find(url_string) do
      nil -> insert_new(url_string)
      url_schema -> update_existing(url_schema, url_string)
    end
  end

  def call(_), do: {:error, :invalid_argument}

  defp insert_new(url_string) do
    {status, image} = extract(url_string)

    Url.changeset(%Url{}, %{url: url_string, status: status, image: image})
    |> Repo.insert()
  end

  defp update_existing(url, url_string) do
    {status, image} = extract(url_string)

    case status do
      "error" ->
        {:ok, url}

      _ ->
        Url.changeset(url, %{url: url_string, status: status, image: image})
        |> Repo.update()
    end
  end

  def find(url_string), do: Url |> where(url: ^url_string) |> Repo.one()

  def extract(url_string) do
    case ExtractOg.call(url_string) do
      {:ok, metadata} -> {"processed", metadata.image}
      {:error, _} -> {"error", nil}
    end
  end
end
