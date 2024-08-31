defmodule Hello.Repo.Migrations.CreateUsersTableWithUuid do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :full_name, :string, null: false
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :role, :string, null: false, default: "editor"

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
