defmodule HelloWeb.ContactController do
  use HelloWeb, :controller
  alias Hello.Contact
  alias Hello.Repo

  def create(conn, %{
        "full_name" => full_name,
        "email" => email,
        "phone_number" => phone_number,
        "message" => message,
        "terms_and_conditions" => terms_and_conditions
      }) do
    # Convert "terms_and_conditions" to a boolean
    terms_and_conditions = terms_and_conditions == "true"

    contact_params = %{
      "full_name" => full_name,
      "email" => email,
      "phone_number" => phone_number,
      "message" => message,
      "terms_and_conditions" => terms_and_conditions
    }

    changeset = Contact.changeset(%Contact{}, contact_params)

    case Repo.insert(changeset) do
      {:ok, _contact} ->
        conn
        |> put_flash(:info, "Contact form submitted successfully.")
        |> redirect(to: "/")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an error submitting the form.")
        |> render("new.html", changeset: changeset)
    end
  end
end
