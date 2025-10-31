defmodule Malarkey.Social do
  @moduledoc """
  The Social context.
  """

  import Ecto.Query, warn: false
  alias Malarkey.Repo

  alias Malarkey.Social.{Post, Like, Follow}
  alias Malarkey.Accounts.User

  @doc """
  Returns the list of posts for the home timeline.
  Includes posts from users that the given user follows.
  """
  def list_timeline_posts(user, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    following_ids =
      from(f in Follow,
        where: f.follower_id == ^user.id,
        select: f.following_id
      )
      |> Repo.all()

    user_ids = [user.id | following_ids]

    from(t in Post,
      where: t.user_id in ^user_ids,
      order_by: [desc: t.inserted_at],
      limit: ^limit,
      preload: [:user, :reply_to, :repost_of, :quote_post]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of posts for a specific user.
  """
  def list_user_posts(user, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    from(t in Post,
      where: t.user_id == ^user.id and is_nil(t.repost_of_id),
      order_by: [desc: t.inserted_at],
      limit: ^limit,
      preload: [:user, :reply_to, :quote_post]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of posts with media for a specific user.
  """
  def list_user_media_posts(user, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    from(t in Post,
      where: t.user_id == ^user.id and fragment("cardinality(?) > 0", t.media_urls),
      order_by: [desc: t.inserted_at],
      limit: ^limit,
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of posts liked by a specific user.
  """
  def list_user_liked_posts(user, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    from(t in Post,
      join: l in Like,
      on: l.post_id == t.id,
      where: l.user_id == ^user.id,
      order_by: [desc: l.inserted_at],
      limit: ^limit,
      preload: [:user, :reply_to, :quote_post]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  @doc """
  Gets a single post, raising if not found.
  Accepts both string UUIDs and Ecto.UUID binaries.
  """
  def get_post!(id) when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} ->
        Post
        |> Repo.get!(uuid)
        |> Repo.preload([:user, :reply_to, :repost_of, :quote_post])
      :error ->
        raise Ecto.NoResultsError, queryable: Post
    end
  end

  def get_post!(id) do
    Post
    |> Repo.get!(id)
    |> Repo.preload([:user, :reply_to, :repost_of, :quote_post])
  end

  @doc """
  Gets a single post without raising.

  Returns `nil` if the Post does not exist.
  Accepts both string UUIDs and Ecto.UUID binaries.

  ## Examples

      iex> get_post("123e4567-e89b-12d3-a456-426614174000")
      %Post{}

      iex> get_post("invalid")
      nil

  """
  def get_post(id) when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} ->
        case Repo.get(Post, uuid) do
          nil -> nil
          post -> Repo.preload(post, [:user, :reply_to, :repost_of, :quote_post])
        end
      :error -> nil
    end
  end

  def get_post(id) do
    case Repo.get(Post, id) do
      nil -> nil
      post -> Repo.preload(post, [:user, :reply_to, :repost_of, :quote_post])
    end
  end

  @doc """
  Gets post replies.
  """
  def list_post_replies(post, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    from(t in Post,
      where: t.reply_to_id == ^post.id,
      order_by: [asc: t.inserted_at],
      limit: ^limit,
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Gets threaded replies for a post with nested structure.
  Returns a map of post_id => replies for building thread trees.
  Accepts both string UUIDs and Ecto.UUID binaries.
  """
  def get_threaded_replies(post_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 500)

    # Convert string UUID to binary format for Postgres
    uuid = case Ecto.UUID.dump(post_id) do
      {:ok, binary_uuid} -> binary_uuid
      :error -> post_id  # Already in binary format
    end

    # Get all replies in the thread recursively
    query = """
    WITH RECURSIVE reply_tree AS (
      -- Base case: direct replies to the post
      SELECT p.*, 0 as depth, ARRAY[p.id] as path
      FROM posts p
      WHERE p.reply_to_id = $1

      UNION ALL

      -- Recursive case: replies to replies
      SELECT p.*, rt.depth + 1, rt.path || p.id
      FROM posts p
      INNER JOIN reply_tree rt ON p.reply_to_id = rt.id
      WHERE NOT p.id = ANY(rt.path) -- Prevent cycles
        AND rt.depth < 10 -- Limit depth
    )
    SELECT * FROM reply_tree ORDER BY path LIMIT $2
    """

    result = Ecto.Adapters.SQL.query!(Repo, query, [uuid, limit])

    # Convert results to Post structs and preload associations
    reply_ids = Enum.map(result.rows, fn row -> Enum.at(row, 0) end)

    from(p in Post,
      where: p.id in ^reply_ids,
      preload: [:user, :reply_to]
    )
    |> Repo.all()
    |> Enum.group_by(& &1.reply_to_id)
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    result =
      %Post{}
      |> Post.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, post} ->
        # Increment user's posts count
        from(u in User, where: u.id == ^post.user_id)
        |> Repo.update_all(inc: [posts_count: 1])

        # If it's a reply, increment the parent's replies count
        if post.reply_to_id do
          from(t in Post, where: t.id == ^post.reply_to_id)
          |> Repo.update_all(inc: [replies_count: 1])
        end

        # Broadcast the new post
        Phoenix.PubSub.broadcast(
          Malarkey.PubSub,
          "posts:new",
          {:new_post, Repo.preload(post, [:user, :reply_to, :quote_post])}
        )

        {:ok, Repo.preload(post, [:user, :reply_to, :quote_post])}

      error ->
        error
    end
  end

  @doc """
  Checks if a user has reposted a post.
  """
  def reposted_by_user?(user_id, post_id) do
    from(t in Post,
      where: t.user_id == ^user_id and t.repost_of_id == ^post_id
    )
    |> Repo.exists?()
  end

  @doc """
  Creates a repost.
  """
  def create_repost(user_id, post_id) do
    # Check if already reposted
    existing =
      from(t in Post,
        where: t.user_id == ^user_id and t.repost_of_id == ^post_id
      )
      |> Repo.one()

    if existing do
      {:error, :already_reposted}
    else
      result =
        %Post{}
        |> Post.repost_changeset(%{user_id: user_id, repost_of_id: post_id})
        |> Repo.insert()

      case result do
        {:ok, repost} ->
          # Increment the original post's reposts count
          from(t in Post, where: t.id == ^post_id)
          |> Repo.update_all(inc: [reposts_count: 1])

          # Increment user's posts count
          from(u in User, where: u.id == ^user_id)
          |> Repo.update_all(inc: [posts_count: 1])

          {:ok, Repo.preload(repost, [:user, :repost_of])}

        error ->
          error
      end
    end
  end

  @doc """
  Deletes a repost.
  """
  def delete_repost(user_id, post_id) do
    from(t in Post,
      where: t.user_id == ^user_id and t.repost_of_id == ^post_id
    )
    |> Repo.one()
    |> case do
      nil ->
        {:error, :not_found}

      repost ->
        Repo.delete(repost)

        # Decrement the original post's reposts count
        from(t in Post, where: t.id == ^post_id)
        |> Repo.update_all(inc: [reposts_count: -1])

        # Decrement user's posts count
        from(u in User, where: u.id == ^user_id)
        |> Repo.update_all(inc: [posts_count: -1])

        {:ok, repost}
    end
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    result = Repo.delete(post)

    case result do
      {:ok, deleted_post} ->
        # Decrement user's posts count
        from(u in User, where: u.id == ^deleted_post.user_id)
        |> Repo.update_all(inc: [posts_count: -1])

        {:ok, deleted_post}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  ## Likes

  @doc """
  Creates a like.
  """
  def create_like(attrs \\ %{}) do
    result =
      %Like{}
      |> Like.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, like} ->
        # Increment post's likes count
        from(t in Post, where: t.id == ^like.post_id)
        |> Repo.update_all(inc: [likes_count: 1])

        # Broadcast the like
        Phoenix.PubSub.broadcast(
          Malarkey.PubSub,
          "post:#{like.post_id}",
          {:like_added, like}
        )

        {:ok, like}

      {:error, changeset} ->
        # If it's a unique constraint error, it means already liked
        if changeset.errors[:user_id] || changeset.errors[:post_id] do
          {:error, :already_liked}
        else
          {:error, changeset}
        end
    end
  end

  @doc """
  Deletes a like.
  """
  def delete_like(user_id, post_id) do
    from(l in Like,
      where: l.user_id == ^user_id and l.post_id == ^post_id
    )
    |> Repo.one()
    |> case do
      nil ->
        {:error, :not_found}

      like ->
        Repo.delete(like)

        # Decrement post's likes count
        from(t in Post, where: t.id == ^post_id)
        |> Repo.update_all(inc: [likes_count: -1])

        # Broadcast the unlike
        Phoenix.PubSub.broadcast(
          Malarkey.PubSub,
          "post:#{post_id}",
          {:like_removed, like}
        )

        {:ok, like}
    end
  end

  @doc """
  Checks if a user has liked a post.
  """
  def liked_by_user?(user_id, post_id) do
    Repo.exists?(
      from l in Like,
        where: l.user_id == ^user_id and l.post_id == ^post_id
    )
  end

  ## Follows

  @doc """
  Creates a follow relationship.
  """
  def create_follow(attrs \\ %{}) do
    result =
      %Follow{}
      |> Follow.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, follow} ->
        # Increment follower's following count
        from(u in User, where: u.id == ^follow.follower_id)
        |> Repo.update_all(inc: [following_count: 1])

        # Increment following's followers count
        from(u in User, where: u.id == ^follow.following_id)
        |> Repo.update_all(inc: [followers_count: 1])

        # Broadcast the follow
        Phoenix.PubSub.broadcast(
          Malarkey.PubSub,
          "user:#{follow.following_id}",
          {:new_follower, follow}
        )

        {:ok, follow}

      {:error, changeset} ->
        # If it's a unique constraint error, it means already following
        if changeset.errors[:follower_id] || changeset.errors[:following_id] do
          {:error, :already_following}
        else
          {:error, changeset}
        end
    end
  end

  @doc """
  Deletes a follow relationship.
  """
  def delete_follow(follower_id, following_id) do
    from(f in Follow,
      where: f.follower_id == ^follower_id and f.following_id == ^following_id
    )
    |> Repo.one()
    |> case do
      nil ->
        {:error, :not_found}

      follow ->
        Repo.delete(follow)

        # Decrement follower's following count
        from(u in User, where: u.id == ^follower_id)
        |> Repo.update_all(inc: [following_count: -1])

        # Decrement following's followers count
        from(u in User, where: u.id == ^following_id)
        |> Repo.update_all(inc: [followers_count: -1])

        {:ok, follow}
    end
  end

  @doc """
  Checks if a user is following another user.
  """
  def following?(follower_id, following_id) do
    Repo.exists?(
      from f in Follow,
        where: f.follower_id == ^follower_id and f.following_id == ^following_id
    )
  end

  @doc """
  Gets a list of followers for a user.
  """
  def list_followers(user, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    from(u in User,
      join: f in Follow,
      on: f.follower_id == u.id,
      where: f.following_id == ^user.id,
      order_by: [desc: f.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets a list of users that a user is following.
  """
  def list_following(user, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    from(u in User,
      join: f in Follow,
      on: f.following_id == u.id,
      where: f.follower_id == ^user.id,
      order_by: [desc: f.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end
end
