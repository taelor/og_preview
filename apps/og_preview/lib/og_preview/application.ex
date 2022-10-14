defmodule OgPreview.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      OgPreview.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: OgPreview.PubSub}
      # Start a worker by calling: OgPreview.Worker.start_link(arg)
      # {OgPreview.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: OgPreview.Supervisor)
  end
end
