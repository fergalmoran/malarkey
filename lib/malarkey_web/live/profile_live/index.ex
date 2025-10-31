defmodule MalarkeyWeb.ProfileLive.Index do
  use MalarkeyWeb, :live_view

  import MalarkeyWeb.Components.UI
  import MalarkeyWeb.Components.Posts

  alias Malarkey.Accounts
  alias Malarkey.Social

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    user =
      case Accounts.get_user_by_username(username) do
        nil -> raise Ecto.NoResultsError, queryable: Malarkey.Accounts.User
        user -> user
      end

    {:ok,
     socket
     |> assign(:profile_user, user)
     |> assign(:page_title, "@#{username}")
     |> assign(:active_tab, :posts)
     |> load_posts()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:active_tab, :posts)
    |> load_posts()
  end

  defp apply_action(socket, :replies, _params) do
    socket
    |> assign(:active_tab, :replies)
    |> load_replies()
  end

  defp apply_action(socket, :media, _params) do
    socket
    |> assign(:active_tab, :media)
    |> load_media()
  end

  defp apply_action(socket, :likes, _params) do
    socket
    |> assign(:active_tab, :likes)
    |> load_likes()
  end

  @impl true
  def handle_event("follow", _params, socket) do
    case Social.create_follow(%{
           follower_id: socket.assigns.current_user.id,
           following_id: socket.assigns.profile_user.id
         }) do
      {:ok, _follow} ->
        updated_user = Accounts.get_user!(socket.assigns.profile_user.id)
        {:noreply, assign(socket, :profile_user, updated_user)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to follow user")}
    end
  end

  @impl true
  def handle_event("unfollow", _params, socket) do
    case Social.delete_follow(
           socket.assigns.current_user.id,
           socket.assigns.profile_user.id
         ) do
      {:ok, _} ->
        updated_user = Accounts.get_user!(socket.assigns.profile_user.id)
        {:noreply, assign(socket, :profile_user, updated_user)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to unfollow user")}
    end
  end

  @impl true
  def handle_event("like_post", %{"id" => id}, socket) do
    case Social.create_like(%{user_id: socket.assigns.current_user.id, post_id: id}) do
      {:ok, _like} ->
        {:noreply, reload_current_tab(socket)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to like post")}
    end
  end

  @impl true
  def handle_event("unlike_post", %{"id" => id}, socket) do
    case Social.delete_like(socket.assigns.current_user.id, id) do
      {:ok, _} ->
        {:noreply, reload_current_tab(socket)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to unlike post")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <!-- Profile Header -->
            <div class="border-b border-gray-200 dark:border-gray-800">
        <!-- Header Section -->
        <%= if @profile_user.header_url do %>
          <div class="relative h-48 bg-gradient-to-r from-blue-400 to-purple-500">
            <img
              src={@profile_user.header_url}
              alt="Header"
              class="w-full h-full object-cover"
            />
          </div>
        <% else %>
          <div class="h-48 bg-gradient-to-r from-blue-400 to-purple-500"></div>
        <% end %>

        <!-- Avatar Section (overlapping header) -->
        <div class="flex justify-between items-start px-4 -mt-16 relative z-10">
          <div class="flex-shrink-0">
            <%= if @profile_user.avatar_url do %>
              <img
                src={@profile_user.avatar_url}
                alt={@profile_user.display_name || @profile_user.username}
                class="w-32 h-32 rounded-full border-4 border-white dark:border-gray-900 object-cover"
              />
            <% else %>
              <div class="w-32 h-32 rounded-full bg-gradient-to-br from-blue-400 to-purple-500 flex items-center justify-center text-white text-4xl font-bold border-4 border-white dark:border-gray-900">
                <%= String.first(@profile_user.display_name || @profile_user.username) |> String.upcase() %>
              </div>
            <% end %>
          </div>

          <div class="mt-3">
            <%= if @current_user.id == @profile_user.id do %>
              <.link
                navigate={~p"/settings/profile"}
                class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-full font-bold hover:bg-gray-100 dark:hover:bg-gray-800"
              >
                Edit Profile
              </.link>
            <% else %>
              <%= if following?(@current_user, @profile_user) do %>
                <button
                  phx-click="unfollow"
                  class="px-4 py-2 bg-black text-white dark:bg-white dark:text-black rounded-full font-bold hover:opacity-80"
                >
                  Following
                </button>
              <% else %>
                <button
                  phx-click="follow"
                  class="px-4 py-2 bg-black text-white dark:bg-white dark:text-black rounded-full font-bold hover:opacity-80"
                >
                  Follow
                </button>
              <% end %>
            <% end %>
          </div>
        </div>

        <div class="px-4 pb-4 mt-4">
          <div class="space-y-2">
            <div>
              <h1 class="text-xl font-bold">
                <%= @profile_user.display_name || @profile_user.username %>
              </h1>
              <p class="text-gray-500">@<%= @profile_user.username %></p>
            </div>

            <%= if @profile_user.bio do %>
              <p class="whitespace-pre-wrap"><%= @profile_user.bio %></p>
            <% end %>

            <div class="flex flex-wrap gap-3 text-gray-500">
              <%= if @profile_user.location do %>
                <div class="flex items-center space-x-1">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                    />
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                    />
                  </svg>
                  <span><%= @profile_user.location %></span>
                </div>
              <% end %>

              <%= if @profile_user.website do %>
                <div class="flex items-center space-x-1">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"
                    />
                  </svg>
                  <a href={@profile_user.website} target="_blank" class="text-blue-500 hover:underline">
                    <%= URI.parse(@profile_user.website).host || @profile_user.website %>
                  </a>
                </div>
              <% end %>

              <div class="flex items-center space-x-1">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                  />
                </svg>
                <span>Joined <%= Timex.format!(@profile_user.inserted_at, "{Mshort} {YYYY}") %></span>
              </div>
            </div>

            <div class="flex space-x-4">
              <div>
                <span class="font-bold"><%= @profile_user.following_count %></span>
                <span class="text-gray-500"> Following</span>
              </div>
              <div>
                <span class="font-bold"><%= @profile_user.followers_count %></span>
                <span class="text-gray-500"> Followers</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Tabs -->
      <div class="flex border-b border-gray-200 dark:border-gray-700">
        <button
          class={[
            "flex-1 py-4 font-bold hover:bg-gray-100 dark:hover:bg-gray-800",
            @active_tab == :posts && "border-b-4 border-blue-500"
          ]}
        >
          Posts
        </button>
        <button
          class={[
            "flex-1 py-4 font-bold hover:bg-gray-100 dark:hover:bg-gray-800",
            @active_tab == :replies && "border-b-4 border-blue-500"
          ]}
        >
          Replies
        </button>
        <button
          class={[
            "flex-1 py-4 font-bold hover:bg-gray-100 dark:hover:bg-gray-800",
            @active_tab == :media && "border-b-4 border-blue-500"
          ]}
        >
          Media
        </button>
        <button
          class={[
            "flex-1 py-4 font-bold hover:bg-gray-100 dark:hover:bg-gray-800",
            @active_tab == :likes && "border-b-4 border-blue-500"
          ]}
        >
          Likes
        </button>
      </div>

      <!-- Post List -->
      <div id="posts" phx-update="stream" class="space-y-4">
        <.post_card
          :for={{dom_id, post} <- @streams.posts}
          dom_id={dom_id}
          post={post}
          current_user={@current_user}
        />
      </div>
    </div>
    """
  end

  defp load_posts(socket) do
    posts = Social.list_user_posts(socket.assigns.profile_user)
    stream(socket, :posts, posts, reset: true)
  end

  defp load_replies(socket) do
    # For now, just show all posts including replies
    posts = Social.list_user_posts(socket.assigns.profile_user)
    stream(socket, :posts, posts, reset: true)
  end

  defp load_media(socket) do
    posts = Social.list_user_media_posts(socket.assigns.profile_user)
    stream(socket, :posts, posts, reset: true)
  end

  defp load_likes(socket) do
    posts = Social.list_user_liked_posts(socket.assigns.profile_user)
    stream(socket, :posts, posts, reset: true)
  end

  defp reload_current_tab(socket) do
    case socket.assigns.active_tab do
      :posts -> load_posts(socket)
      :replies -> load_replies(socket)
      :media -> load_media(socket)
      :likes -> load_likes(socket)
    end
  end

  defp following?(current_user, profile_user) do
    Social.following?(current_user.id, profile_user.id)
  end
end
