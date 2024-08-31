# lib/hello/news.ex
defmodule Hello.News do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hello.User

  @derive {Jason.Encoder,
           only: [
             :id,
             :news_title,
             :news_content,
             :news_status,
             :news_cover,
             :news_author_id,
             :inserted_at,
             :updated_at
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "news" do
    field :news_title, :string
    field :news_content, :string
    field :news_status, :string, default: "draft"
    field :news_cover, :string
    belongs_to :news_author, User, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(news, attrs) do
    news
    |> cast(attrs, [:news_title, :news_content, :news_status, :news_cover, :news_author_id])
    |> validate_required([:news_title, :news_content, :news_author_id])
    |> validate_inclusion(:news_status, ["draft", "published"])
    |> unique_constraint(:news_title)
  end
end
