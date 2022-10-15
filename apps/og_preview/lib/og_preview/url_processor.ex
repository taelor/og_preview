defmodule OgPreview.UrlProcessor do
  use Broadway

  alias Broadway.Message

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {OgPreview.UrlQueue, []},
        transformer: {__MODULE__, :transform, []}
      ],
      processors: [
        default: [concurrency: 32]
      ]
    )
  end

  def handle_message(_processor_name, message, _context) do
    message
    |> Message.update_data(&process_data/1)
    |> Message.put_batcher(:s3)
  end

  defp process_data(data) do
    {url, from} = data

    {:ok, url} = OgPreview.ProcessUrl.call(url)

    publish_image(from, url)
  end

  def transform(event, _),
    do: %Message{data: event, acknowledger: {__MODULE__, :ack_id, :ack_data}}

  def ack(_, _, _), do: :ok

  defp publish_image(from, %{image: nil, url: url}),
    do: Phoenix.PubSub.broadcast(OgPreview.PubSub, "og_preview:#{from}", {:no_image, url})

  defp publish_image(from, %{image: image}),
    do: Phoenix.PubSub.broadcast(OgPreview.PubSub, "og_preview:#{from}", {:image, image})
end
