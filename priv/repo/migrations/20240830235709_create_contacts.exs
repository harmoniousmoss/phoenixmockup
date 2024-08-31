defmodule Hello.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :full_name, :string, null: false
      add :email, :string, null: false
      add :phone_number, :string
      add :message, :text, null: false
      add :terms_and_conditions, :boolean, null: false, default: false

      timestamps()
    end
  end
end
