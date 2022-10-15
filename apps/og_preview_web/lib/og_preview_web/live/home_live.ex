defmodule OgPreviewWeb.HomeLive do
  use OgPreviewWeb, :live_view

  alias OgPreview.UrlQueue

  def mount(_params, session, socket) do
    id = Ecto.UUID.generate()

    Phoenix.PubSub.subscribe(OgPreview.PubSub, "og_preview:#{id}")

    {:ok, assign(socket, id: id, image: nil, no_image: false)}
  end

  def render(assigns) do
    OgPreviewWeb.HomeView.render("index.html", assigns)
  end

  def handle_event("preview", %{"preview" => %{"url" => url}}, socket) do
    if url != "" do
      UrlQueue.enqueue(url, socket.assigns.id)
    end

    {:noreply, assign(socket, image: nil, no_image: false)}
  end

  def handle_info({:image, image}, socket) do
    {:noreply, assign(socket, image: image, no_image: false)}
  end

  def handle_info({:no_image, url}, socket) do
    {:noreply, assign(socket, no_image: url)}
  end
end
