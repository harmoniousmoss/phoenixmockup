defmodule Hello.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Jason.Encoder,
           only: [
             :id,
             :full_name,
             :email,
             :phone_number,
             :message,
             :terms_and_conditions,
             :inserted_at,
             :updated_at
           ]}
  schema "contacts" do
    field :full_name, :string
    field :email, :string
    field :phone_number, :string
    field :message, :string
    field :terms_and_conditions, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:full_name, :email, :phone_number, :message, :terms_and_conditions])
    |> validate_required([:full_name, :email, :message, :terms_and_conditions])
    |> validate_acceptance(:terms_and_conditions,
      message: "You must accept the terms and conditions"
    )
    |> validate_format(:email, ~r/@/)
    |> validate_length(:message, min: 10, message: "Message must be at least 10 characters long")
  end
end
