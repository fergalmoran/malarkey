defmodule Malarkey.Timeline.PostUserLike do
  import Ecto.Query
  use Ecto.Schema
  alias Malarkey.Timeline.PostUserLike

  @primary_key false
  schema "user_likes" do
    belongs_to :user, Malarkey.Accounts.User, primary_key: true
    belongs_to :post, Malarkey.Timeline.Post, primary_key: true
    timestamps()
  end

  def user_post_like_query(user, post) do
    from PostUserLike, where: [user_id: ^user.id, post_id: ^post.id]
  end
end
