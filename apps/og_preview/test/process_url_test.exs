defmodule OgPreview.ProcessUrlTest do
  use OgPreview.DataCase, async: true

  alias OgPreview.ProcessUrl

  import OgPreview.Factory
  import Mox

  setup :verify_on_exit!

  describe "new url and error extracting" do
    setup [:mock_error]

    test "it should store an error" do
      {:ok, url} = ProcessUrl.call("https://www.getluna.com/")
      assert url.status == "error"
    end
  end

  describe "new url and ok extracting" do
    setup [:mock_ok]

    test "it should store image url" do
      {:ok, url} = ProcessUrl.call("https://www.getluna.com/")
      assert is_binary(url.image)
    end
  end

  describe "existing url and error extracting" do
    setup [:url, :mock_error]

    test "it should not update anything", %{url: existing_url} do
      {:ok, url} = ProcessUrl.call("https://www.getluna.com/")
      assert url == existing_url
    end
  end

  describe "existing url and ok extracting, but same url" do
    setup [:url, :mock_ok]

    test "it should not update anything", %{url: existing_url} do
      {:ok, url} = ProcessUrl.call("https://www.getluna.com/")
      assert url == existing_url
    end
  end

  describe "existing url and ok extracting" do
    setup [:url, :mock_changed]

    test "it should update image url if changed", %{url: existing_url} do
      {:ok, url} = ProcessUrl.call("https://www.getluna.com/")
      assert is_binary(url.image)
      assert url.image != existing_url.image
    end
  end

  # Named Setups

  def url(_) do
    url =
      insert!(:url,
        url: "https://www.getluna.com/",
        image: "https://public-images.getluna.com/images/social/facebook.png",
        status: "processed"
      )

    %{url: url}
  end

  def mock_error(_) do
    expect(HTTPoison.BaseMock, :get, fn _, _ ->
      {:error, %HTTPoison.Error{id: nil, reason: :nxdomain}}
    end)

    :ok
  end

  def mock_ok(_) do
    expect(HTTPoison.BaseMock, :get, fn _, _ ->
      {:ok, %{status_code: 200, body: http("facebook.png")}}
    end)

    :ok
  end

  def mock_changed(_) do
    expect(HTTPoison.BaseMock, :get, fn _, _ ->
      {:ok, %{status_code: 200, body: http("facebook_2023.png")}}
    end)

    :ok
  end

  # Helpers

  # TODO: DRY this and the extract_og_test.exs call into support helper
  def http(file) do
    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta property="og:image" content="https://public-images.getluna.com/images/social/#{file}" />
      </head>
    </body>
    """
  end
end
