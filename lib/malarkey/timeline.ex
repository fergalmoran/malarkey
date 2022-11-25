defmodule Malarkey.Timeline do
  @moduledoc """
  The Timeline context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset

  alias Malarkey.Repo
  alias Malarkey.Accounts

  alias Malarkey.Timeline.Post

  def list_posts() do
    # preloads = Keyword.get(opts, :preloads, [])

    Post
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  def get_post!(id), do: Repo.get!(Post, id)

  def create_post(user, attrs \\ %{}) do
    %Post{user_id: user.id}
    |> Post.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:post_created)
  end

  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
    |> broadcast(:post_created)
  end

  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
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
