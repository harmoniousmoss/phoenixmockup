defmodule HelloWeb.NewsController do
  use HelloWeb, :controller
  alias Hello.News
  alias Hello.Repo
  alias ExAws.S3

  plug HelloWeb.Plugs.AuthenticateUser when action in [:create, :update]

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

  def update(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user
    news = Repo.get!(News, id) |> Repo.preload(:news_author)

    case user.role do
      "administrator" ->
        update_news(conn, news, params, user)

      "editor" ->
        if news.news_author_id == user.id do
          update_news(conn, news, params, user)
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "You are not authorized to edit this news."})
        end

      _ ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "You are not authorized to edit this news."})
    end
  end

  defp update_news(
         conn,
         news,
         params,
         _user
       ) do
    changeset =
      news
      |> News.changeset(%{
        "news_title" => Map.get(params, "news_title", news.news_title),
        "news_content" => Map.get(params, "news_content", news.news_content),
        "news_status" => Map.get(params, "news_status", news.news_status),
        "news_cover" => Map.get(params, "news_cover", news.news_cover)
      })

    case Repo.update(changeset) do
      {:ok, updated_news} ->
        updated_news = Repo.preload(updated_news, :news_author)

        response = %{
          id: updated_news.id,
          news_title: updated_news.news_title,
          news_content: updated_news.news_content,
          news_status: updated_news.news_status,
          news_cover: updated_news.news_cover,
          news_author_id: updated_news.news_author_id,
          news_author_full_name: updated_news.news_author.full_name,
          inserted_at: updated_news.inserted_at,
          updated_at: updated_news.updated_at
        }

        conn
        |> put_status(:ok)
        |> json(response)

      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "Changeset errors")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end
end
