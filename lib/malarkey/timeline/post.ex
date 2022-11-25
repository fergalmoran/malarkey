defmodule Malarkey.Timeline.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias Malarkey.Accounts.User

  schema "posts" do
    field :body, :string
    field :likes_count, :integer, default: 0
    field :repost_count, :integer, default: 0

    belongs_to(:user, User)

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:body, :user_id])
    |> validate_required([:body])
    |> validate_required([:user_id])
    |> validate_length(:body, min: 2, max: 250)
  end
end
