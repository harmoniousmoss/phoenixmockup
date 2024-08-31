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

  plug HelloWeb.Plugs.AuthenticateUser when action in [:approve_user, :index, :show]

  def approve_user(conn, %{"id" => id}) do
    user = Repo.get!(User, id)

    changeset =
      user
      |> Ecto.Changeset.change(status: "approved")
      |> Ecto.Changeset.validate_inclusion(:status, ["pending", "approved"])

    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User approved successfully.")
        |> json(%{message: "User approved successfully."})

      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "Changeset errors")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Unable to approve user.", details: format_errors(changeset)})
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  def index(conn, _params) do
    users = Repo.all(User)

    conn
    |> put_status(:ok)
    |> json(users)
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get!(User, id)

    # Restrict access based on user role
    current_user_id = conn.assigns.current_user.id
    current_user_role = conn.assigns.current_user.role

    case current_user_role do
      "administrator" ->
        render_user(conn, user)

      "editor" ->
        if current_user_id == user.id do
          render_user(conn, user)
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "You are not authorized to access this resource."})
        end

      _ ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "You are not authorized to access this resource."})
    end
  end

  defp render_user(conn, user) do
    conn
    |> put_status(:ok)
    |> json(user)
  end
end
