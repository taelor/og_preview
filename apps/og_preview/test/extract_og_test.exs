defmodule OgPreview.ExtractOgTest do
  use OgPreview.DataCase, async: true

  import Mox

  alias OgPreview.ExtractOg

  setup :verify_on_exit!

  test "returns error tuple when not URL" do
    assert ExtractOg.call(nil) == {:error, :not_url}
    assert ExtractOg.call("") == {:error, :not_url}
    assert ExtractOg.call("foo") == {:error, :not_url}
    assert ExtractOg.call("ws://websocket.com") == {:error, :not_url}
  end

  test "returns error tuple when not 200" do
    expect(HTTPoison.BaseMock, :get, fn _, _ ->
      {:ok, %{status_code: 502}}
    end)

    assert ExtractOg.call("https://www.badurl.com/") == {:error, 502}
  end

  test "returns error tuple when client returns error" do
    expect(HTTPoison.BaseMock, :get, fn _, _ ->
      {:error, %HTTPoison.Error{id: nil, reason: :nxdomain}}
    end)

    assert ExtractOg.call("https://www.badurl.com/") == {:error, :nxdomain}
  end

  test "returns extracted OG data (mock)" do
    expect(HTTPoison.BaseMock, :get, fn _, _ ->
      {:ok, %{status_code: 200, body: http()}}
    end)

    {:ok, %OpenGraph{image: image}} = ExtractOg.call("https://www.getluna.com/")

    assert image == "https://public-images.getluna.com/images/social/facebook.png"
  end

  @tag integration: true
  test "returns extracted OG data (integration)" do
    client = Application.get_env(:og_preview, :http_client)

    Application.put_env(:og_preview, :http_client, HTTPoison)

    {:ok, %OpenGraph{image: image}} = ExtractOg.call("https://www.getluna.com/")

    assert image == "https://public-images.getluna.com/images/social/facebook.png"

    Application.put_env(:og_preview, :http_client, client)
  end

  def http() do
    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta property="og:url"   content="https://www.getluna.com" />
        <meta property="og:type"  content="website" />
        <meta property="og:image" content="https://public-images.getluna.com/images/social/facebook.png" />
        <meta property="og:title"        content="In-Home Physical Therapy | Luna Physical Therapy" />
        <meta property="og:description"  content="Luna physical therapists come to you! We accept all major insurances and Medicare. Serving patients across the United States." />
      </head>
    </body>
    """
  end
end
