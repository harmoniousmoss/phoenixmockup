defmodule HelloWeb.Plugs.AuthenticateAdmin do
  import Plug.Conn
  # Import the json/2 function
  import Phoenix.Controller, only: [json: 2]
  alias Hello.Repo
  alias Hello.User

  def init(default), do: default

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user_id} <-
           Phoenix.Token.verify(HelloWeb.Endpoint, "user_auth", token, max_age: 86400),
         %User{role: "administrator"} <- Repo.get(User, user_id) do
      conn
    else
      _ ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "You are not authorized to access this resource."})
        |> halt()
    end
  end
end
