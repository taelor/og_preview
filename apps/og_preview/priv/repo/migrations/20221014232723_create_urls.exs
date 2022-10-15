defmodule OgPreview.Repo.Migrations.CreateUrls do
  use Ecto.Migration

  def change do
    create table(:urls, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:url, :string)
      add(:image, :string)
      add(:status, :string)

      timestamps()
    end

    create(unique_index(:urls, [:url]))
    create(index(:urls, [:status]))
  end
end
