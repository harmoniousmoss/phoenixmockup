defmodule HelloWeb.UserController do
  use HelloWeb, :controller
  alias Hello.User
  alias Hello.Repo

  def create(conn, %{"full_name" => full_name, "email" => email, "password" => password}) do
    user_params = %{
      "full_name" => full_name,
      "email" => email,
      "password" => password
    }

    changeset = User.changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, _user} ->
        # Generate token or any other necessary actions after user creation
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: "/")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an error creating the user.")
        |> render("new.html", changeset: changeset)
    end
  end

  def signin(conn, %{"email" => email, "password" => password}) do
    case Repo.get_by(User, email: email) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password."})

      user ->
        if user.status == "approved" && Bcrypt.verify_pass(password, user.password_hash) do
          token = Phoenix.Token.sign(HelloWeb.Endpoint, "user_auth", user.id)

          conn
          |> json(%{token: token, message: "Sign-in successful."})
        else
          conn
          |> put_status(:unauthorized)
          |> json(%{error: "Invalid email or password, or user not approved."})
        end
    end
  end
end
