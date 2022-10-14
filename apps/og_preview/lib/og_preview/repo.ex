defmodule OgPreview.Repo do
  use Ecto.Repo,
    otp_app: :og_preview,
    adapter: Ecto.Adapters.Postgres
end
