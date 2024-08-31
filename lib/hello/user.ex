defmodule Hello.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Bcrypt

  @status_values ["pending", "approved"]
  @role_values ["editor", "administrator"]

  # Set the primary key to be a binary_id (UUID)
  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "users" do
    field :full_name, :string
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :status, :string, default: "pending"
    field :role, :string, default: "editor"

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:full_name, :email, :password, :status, :role])
    |> validate_required([:full_name, :email, :password, :status, :role])
    |> validate_length(:password, min: 8)
    |> validate_format(:email, ~r/@/)
    |> validate_inclusion(:status, @status_values)
    |> validate_inclusion(:role, @role_values)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      password -> put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
    end
  end
end
