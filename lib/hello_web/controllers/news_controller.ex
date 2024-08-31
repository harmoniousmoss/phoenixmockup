# lib/hello_web/controllers/news_controller.ex
defmodule HelloWeb.NewsController do
  use HelloWeb, :controller
  alias Hello.News
  alias Hello.Repo

  plug HelloWeb.Plugs.AuthenticateUser when action in [:create]

  def create(conn, %{
        "news_title" => news_title,
        "news_content" => news_content,
        "news_cover" => %Plug.Upload{} = upload
      }) do
    # Get the current authenticated user from the connection
    user = conn.assigns.current_user

    # Construct the changeset with the authenticated user as the author
    changeset =
      News.changeset(%News{}, %{
        "news_title" => news_title,
        "news_content" => news_content,
        # Default to draft status
        "news_status" => "draft",
        "news_cover" => upload.filename,
        "news_author_id" => user.id
      })

    # Insert the new news record into the database
    case Repo.insert(changeset) do
      {:ok, _news} ->
        conn
        |> put_status(:created)
        |> json(%{message: "News created successfully."})

      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "Changeset errors")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
