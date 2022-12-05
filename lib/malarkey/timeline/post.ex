defmodule Malarkey.Timeline.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias Malarkey.Accounts.User

  schema "posts" do
    field :body, :string
    field :repost_count, :integer, default: 0

    belongs_to(:user, User)

    many_to_many(
      :liked_by,
      User,
      join_through: Malarkey.Timeline.PostUserLike,
      on_replace: :delete
    )

    many_to_many(
      :disliked_by,
      User,
      join_through: Malarkey.Timeline.PostUserDislikes,
      on_replace: :delete
    )

    many_to_many(
      :reposted_by,
      User,
      join_through: Malarkey.Timeline.PostUserRepost,
      on_replace: :delete
    )

    timestamps()
  end

  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:body, :user_id])
    |> cast_assoc(:liked_by, required: false)
    |> validate_required([:body])
    |> validate_required([:user_id])
    |> validate_length(:body, min: 2, max: 250)
  end

  @spec changeset_add_like(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          any,
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def changeset_add_like(post, user, attrs \\ %{}) do
    post
    |> changeset(attrs)
    |> put_assoc(:liked_by, [user])
  end
end
