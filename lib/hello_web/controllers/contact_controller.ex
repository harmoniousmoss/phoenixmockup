defmodule HelloWeb.ContactController do
  use HelloWeb, :controller
  alias Hello.Contact
  alias Hello.Repo

  plug HelloWeb.Plugs.AuthenticateUser when action in [:index, :show, :delete]

  # Ensure only approved users can access the index and show actions
  plug :ensure_approved_user when action in [:index, :show]

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

  def index(conn, _params) do
    contacts = Repo.all(Contact)

    conn
    |> put_status(:ok)
    |> json(contacts)
  end

  def show(conn, %{"id" => id}) do
    case Repo.get(Contact, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Contact not found"})

      contact ->
        conn
        |> put_status(:ok)
        |> json(contact)
    end
  end

  defp ensure_approved_user(conn, _opts) do
    user = conn.assigns.current_user

    if user && user.status == "approved" do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "You are not authorized to access this resource."})
      |> halt()
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    contact = Repo.get!(Contact, id)

    case user.role do
      "administrator" ->
        delete_contact(conn, contact)

      "editor" ->
        delete_contact(conn, contact)

      _ ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "You are not authorized to delete this contact."})
    end
  end

  defp delete_contact(conn, contact) do
    case Repo.delete(contact) do
      {:ok, _deleted_contact} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Contact deleted successfully."})

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Unable to delete the contact."})
    end
  end
end
