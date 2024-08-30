# priv/repo/migrations/*_create_contacts.exs
defmodule Hello.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :full_name, :string, null: false
      add :email, :string, null: false
      add :phone_number, :string
      add :message, :text, null: false
      add :terms_and_conditions, :boolean, default: false, null: false

      timestamps()
    end
  end
end
