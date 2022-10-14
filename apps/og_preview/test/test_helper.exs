ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(OgPreview.Repo, :manual)

Mox.defmock(HTTPoison.BaseMock, for: HTTPoison.Base)

Application.put_env(:og_preview, :http_client, HTTPoison.BaseMock)
