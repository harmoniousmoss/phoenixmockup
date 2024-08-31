defmodule HelloWeb.Plugs.AuthenticateAdmin do
  import Plug.Conn
  alias Hello.Repo
  alias Hello.User
  require Logger

  def init(default), do: default

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user_id} <-
           Phoenix.Token.verify(HelloWeb.Endpoint, "user_auth", token, max_age: 86400),
         {:ok, uuid} <- Ecto.UUID.cast(user_id),
         %User{} = user <- Repo.get(User, uuid) do
      Logger.debug("Authenticated user ID: #{user_id}, UUID: #{uuid}")

      # Assign the user to the connection for later use
      conn
      |> assign(:current_user, user)
    else
      error ->
        Logger.error("Authentication failed: #{inspect(error)}")

        conn
        |> put_status(:forbidden)
        |> Phoenix.Controller.json(%{error: "You are not authorized to access this resource."})
        |> halt()
    end
  end
end
