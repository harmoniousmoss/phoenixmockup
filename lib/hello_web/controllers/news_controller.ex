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
        # Construct the response with the author's full name
        response = %{
          id: news.id,
          news_title: news.news_title,
          news_content: news.news_content,
          news_status: news.news_status,
          news_cover: news.news_cover,
          news_author_id: user.id,
          # Include the author's full name
          news_author_full_name: user.full_name,
          inserted_at: news.inserted_at,
          updated_at: news.updated_at
        }

        conn
        |> put_status(:created)
        |> json(response)

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
    region = System.get_env("AWS_REGION")
    s3_key = "uploads/news_covers/#{filename}"

    {:ok, _} =
      S3.put_object(bucket, s3_key, File.read!(path))
      |> ExAws.request()

    "https://#{bucket}.s3.#{region}.amazonaws.com/#{s3_key}"
  end

  def index(conn, _params) do
    news_list = Repo.all(News) |> Repo.preload(:news_author)

    response =
      Enum.map(news_list, fn news ->
        %{
          id: news.id,
          news_title: news.news_title,
          news_content: news.news_content,
          news_status: news.news_status,
          news_cover: news.news_cover,
          news_author_id: news.news_author_id,
          # Include the author's full name
          news_author_full_name: news.news_author.full_name,
          inserted_at: news.inserted_at,
          updated_at: news.updated_at
        }
      end)

    conn
    |> put_status(:ok)
    |> json(response)
  end

  def show(conn, %{"id" => id}) do
    news = Repo.get!(News, id) |> Repo.preload(:news_author)

    response = %{
      id: news.id,
      news_title: news.news_title,
      news_content: news.news_content,
      news_status: news.news_status,
      news_cover: news.news_cover,
      news_author_id: news.news_author_id,
      # Include the author's full name
      news_author_full_name: news.news_author.full_name,
      inserted_at: news.inserted_at,
      updated_at: news.updated_at
    }

    conn
    |> put_status(:ok)
    |> json(response)
  end
end
