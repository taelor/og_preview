defmodule OgPreview.Url do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "urls" do
    field(:image, :string)
    field(:status, :string)
    field(:url, :string)

    timestamps()
  end

  @doc false
  def changeset(url, attrs) do
    url
    |> cast(attrs, [:url, :image, :status])
    |> validate_required([:url, :status])
  end
end
