# lib/hello_web/controllers/contact_controller.ex
defmodule HelloWeb.ContactController do
  use HelloWeb, :controller
  alias Hello.Contact
  alias Hello.Repo

  def create(conn, %{"contact" => contact_params}) do
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
