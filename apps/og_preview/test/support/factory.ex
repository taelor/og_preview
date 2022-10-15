defmodule OgPreview.Factory do
  alias OgPreview.Repo

  # Factories

  def build(:url) do
    %OgPreview.Url{
      url: "https://www.getluna.com/",
      image: "https://public-images.getluna.com/images/social/facebook.png",
      status: "processed"
    }
  end

  # Convenience API

  def build(factory_name, attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> Repo.insert!()
  end
end
