defmodule HelloWeb.NewsController do
  use HelloWeb, :controller
  alias Hello.News
  alias Hello.Repo
  alias ExAws.S3

  plug HelloWeb.Plugs.AuthenticateUser when action in [:create]

  def create(conn, %{
        "news_title" => news_title,
        "news_content" => news_content,
        "news_cover" => %Plug.Upload{} = upload
      }) do
    # Debug statements to check environment variables
    IO.inspect(System.get_env("AWS_ACCESS_KEY_ID"), label: "AWS_ACCESS_KEY_ID")
    IO.inspect(System.get_env("AWS_SECRET_ACCESS_KEY"), label: "AWS_SECRET_ACCESS_KEY")
    IO.inspect(System.get_env("AWS_REGION"), label: "AWS_REGION")
    IO.inspect(System.get_env("AWS_BUCKET_NAME"), label: "AWS_BUCKET_NAME")

    user = conn.assigns.current_user

    # Upload the file to S3 and get the URL
    s3_url = upload_to_s3(upload)

    changeset =
      News.changeset(%News{}, %{
        "news_title" => news_title,
        "news_content" => news_content,
        # Default to draft status
        "news_status" => "draft",
        "news_cover" => s3_url,
        "news_author_id" => user.id
      })

    case Repo.insert(changeset) do
      {:ok, news} ->
        conn
        |> put_status(:created)
        # Return the full news object
        |> json(news)

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

  defp upload_to_s3(%Plug.Upload{path: path, filename: filename}) do
    bucket = System.get_env("AWS_BUCKET_NAME")
    s3_key = "uploads/news_covers/#{filename}"

    {:ok, _} =
      S3.put_object(bucket, s3_key, File.read!(path))
      |> ExAws.request()

    "https://#{bucket}.s3.#{System.get_env("AWS_REGION")}.amazonaws.com/#{s3_key}"
  end

  def index(conn, _params) do
    news = Repo.all(News)

    conn
    |> put_status(:ok)
    |> json(news)
  end

  def show(conn, %{"id" => id}) do
    news = Repo.get!(News, id)

    conn
    |> put_status(:ok)
    |> json(news)
  end
end
