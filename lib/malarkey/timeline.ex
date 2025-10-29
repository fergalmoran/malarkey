defmodule Malarkey.Timeline do
  @moduledoc """
  The Timeline context.
  """

  import Ecto.Query, warn: false

  alias Malarkey.Timeline.PostUserLike
  alias Malarkey.Repo
  alias Malarkey.Timeline.Post

  def list_posts() do
    # preloads = Keyword.get(opts, :preloads, [])

    Post
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
    |> Repo.preload(:liked_by)
    |> Repo.preload(:disliked_by)
    |> Repo.preload(:reposted_by)
  end

  def get_post!(id) do
    Repo.get!(Post, id)
    |> Repo.preload(:user)
    |> Repo.preload(:liked_by)
    |> Repo.preload(:disliked_by)
    |> Repo.preload(:reposted_by)
  end

  def create_post(user, attrs \\ %{}) do
    %Post{user_id: user.id}
    |> Post.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:post_created)
  end

  def update_post(%Post{} = post, attrs \\ %{}) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
    |> broadcast(:post_updated)
  end

  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def add_like(user, post) do
    if user in post.liked_by do
      Repo.delete_all(PostUserLike.user_post_like_query(user, post))
      |> broadcast(:post_updated)
    else
      post
      |> Repo.preload(:liked_by)
      |> Repo.preload(:user)
      |> Post.changeset_add_like(user)
      |> Repo.update()
      |> broadcast(:post_updated)
    end
  end

  def add_repost(user, post) do
    post
    |> Repo.preload(:reposted_by)
    |> Repo.preload(:user)
    |> Post.changeset_add_repost(user)
    |> Repo.update()
    |> broadcast(:post_created)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Malarkey.PubSub, "posts")
  end

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, post}, event) do
    Phoenix.PubSub.broadcast!(Malarkey.PubSub, "posts", {event, post})
    {:ok, post}
  end
end
