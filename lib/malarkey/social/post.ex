defmodule Malarkey.Social.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "posts" do
    field :body, :string, source: :content
    field :media_urls, {:array, :string}, default: []
    field :media_types, {:array, :string}, default: []
    field :likes_count, :integer, default: 0
    field :reposts_count, :integer, default: 0
    field :replies_count, :integer, default: 0
    field :views_count, :integer, default: 0

    belongs_to :user, Malarkey.Accounts.User
    belongs_to :reply_to, Malarkey.Social.Post
    belongs_to :repost_of, Malarkey.Social.Post
    belongs_to :quote_post, Malarkey.Social.Post

    has_many :likes, Malarkey.Social.Like
    has_many :replies, Malarkey.Social.Post, foreign_key: :reply_to_id
    has_many :reposts, Malarkey.Social.Post, foreign_key: :repost_of_id

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    # Normalize attrs to support both body and content keys
    attrs = normalize_attrs(attrs)

    post
    |> cast(attrs, [:body, :media_urls, :media_types, :user_id, :reply_to_id, :repost_of_id, :quote_post_id], empty_values: [])
    |> ensure_body_for_media()
    |> validate_required([:user_id])
    |> validate_body_or_media()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:reply_to_id)
    |> foreign_key_constraint(:repost_of_id)
    |> foreign_key_constraint(:quote_post_id)
  end

  @doc false
  def repost_changeset(post, attrs) do
    post
    |> cast(attrs, [:user_id, :repost_of_id])
    |> validate_required([:user_id, :repost_of_id])
    |> put_change(:body, " ")
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:repost_of_id)
  end

  # Private functions

  defp normalize_attrs(attrs) when is_map(attrs) do
    # Support both body and content keys for migration
    cond do
      Map.has_key?(attrs, :body) or Map.has_key?(attrs, "body") -> attrs
      Map.has_key?(attrs, :content) -> Map.put(attrs, :body, attrs[:content])
      Map.has_key?(attrs, "content") -> Map.put(attrs, :body, attrs["content"])
      true -> attrs
    end
  end

  defp ensure_body_for_media(changeset) do
    # After cast, if body is nil/empty and media is present, set body to a space
    body = get_field(changeset, :body)
    media_urls = get_field(changeset, :media_urls) || []

    trimmed_body = if is_binary(body), do: String.trim(body), else: ""

    if trimmed_body == "" and length(media_urls) > 0 do
      put_change(changeset, :body, " ")
    else
      changeset
    end
  end

  defp validate_body_or_media(changeset) do
    body = get_field(changeset, :body)
    media_urls = get_field(changeset, :media_urls) || []

    trimmed_body = if is_binary(body), do: String.trim(body), else: ""

    if trimmed_body == "" && Enum.empty?(media_urls) do
      add_error(changeset, :body, "Post must have text or media")
    else
      changeset
      |> validate_length(:body, max: 280, message: "Post is too long (maximum is 280 characters)")
    end
  end
end
