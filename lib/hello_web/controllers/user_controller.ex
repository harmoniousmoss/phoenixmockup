defmodule HelloWeb.UserController do
  use HelloWeb, :controller
  alias Hello.User
  alias Hello.Repo

  def create(conn, %{"user" => user_params}) do
    changeset = User.changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: "/")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an error creating the user.")
        |> render("new.html", changeset: changeset)
    end
  end
end
