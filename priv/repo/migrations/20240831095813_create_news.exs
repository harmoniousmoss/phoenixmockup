defmodule Hello.Repo.Migrations.CreateNews do
  use Ecto.Migration

  def change do
    create table(:news, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :news_title, :string, null: false
      add :news_content, :string, null: false
      add :news_status, :string, null: false, default: "draft"
      add :news_cover, :string
      add :news_author_id, references(:users, type: :binary_id, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:news, [:news_title])
  end
end
