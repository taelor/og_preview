defmodule OgPreview.ExtractOg do
  def call(url) when is_binary(url), do: call(URI.parse(url))

  def call(%URI{host: host, scheme: scheme} = uri)
      when scheme in ["http", "https"] and not is_nil(host),
      do: client().get(uri, []) |> respond()

  def call(_), do: {:error, :not_url}

  defp respond({:ok, %{status_code: 200, body: body}}), do: {:ok, OpenGraph.parse(body)}
  defp respond({:ok, %{status_code: status}}), do: {:error, status}
  defp respond({:error, %{reason: reason}}), do: {:error, reason}

  defp client(), do: Application.get_env(:og_preview, :http_client, HTTPoison)
end
