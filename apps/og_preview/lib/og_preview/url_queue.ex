defmodule OgPreview.UrlQueue do
  use GenStage

  def name(), do: List.first(Broadway.producer_names(OgPreview.UrlProcessor))

  def enqueue(url, pid), do: GenStage.cast(name(), {:enqueue, {url, pid}})

  ## Callbacks

  def init(_), do: {:producer, {:queue.new(), 0}}

  def handle_cast({:enqueue, event}, {queue, pending_demand}) do
    queue = :queue.in(event, queue)
    dispatch_events(queue, pending_demand, [])
  end

  def handle_demand(incoming_demand, {queue, pending_demand}) do
    dispatch_events(queue, incoming_demand + pending_demand, [])
  end

  defp dispatch_events(queue, 0, events) do
    {:noreply, Enum.reverse(events), {queue, 0}}
  end

  defp dispatch_events(queue, demand, events) do
    case :queue.out(queue) do
      {{:value, event}, queue} ->
        dispatch_events(queue, demand - 1, [event | events])

      {:empty, queue} ->
        {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end
