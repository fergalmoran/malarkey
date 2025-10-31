defmodule MalarkeyWeb.ProfileLive.Followers do
  use MalarkeyWeb, :live_view

  import MalarkeyWeb.Components.UI

  alias Malarkey.Accounts
  alias Malarkey.Social

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    user =
      case Accounts.get_user_by_username(username) do
        nil -> raise Ecto.NoResultsError, queryable: Malarkey.Accounts.User
        user -> user
      end

    followers = Social.list_followers(user)

    {:ok,
     socket
     |> assign(:profile_user, user)
     |> assign(:page_title, "@#{username} - Followers")
     |> stream(:followers, followers)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("follow", %{"id" => id}, socket) do
    case Social.create_follow(%{
           follower_id: socket.assigns.current_user.id,
           following_id: id
         }) do
      {:ok, _follow} ->
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to follow user")}
    end
  end

  @impl true
  def handle_event("unfollow", %{"id" => id}, socket) do
    case Social.delete_follow(socket.assigns.current_user.id, id) do
      {:ok, _} ->
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to unfollow user")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <div class="border-b border-gray-200 dark:border-gray-700 p-4">
        <.link class="text-blue-500 hover:underline">
          ← Back
        </.link>
        <h1 class="text-xl font-bold mt-2">
          <%= @profile_user.display_name || @profile_user.username %>
        </h1>
        <p class="text-gray-500">@<%= @profile_user.username %></p>
      </div>

      <div class="border-b border-gray-200 dark:border-gray-700 p-4">
        <h2 class="font-bold text-lg">Followers</h2>
      </div>

      <div id="followers" phx-update="stream">
        <div
          :for={{dom_id, follower} <- @streams.followers}
          id={dom_id}
          class="border-b border-gray-200 dark:border-gray-700 p-4 hover:bg-gray-50 dark:hover:bg-gray-800 transition"
        >
          <div class="flex items-center justify-between">
            <div class="flex space-x-3 flex-1">
              <div class="flex-shrink-0">
                <.avatar user={follower} size="lg" />
              </div>
              <div class="flex-1 min-w-0">
                <div class="font-bold">
                  <%= follower.display_name || follower.username %>
                </div>
                <div class="text-gray-500">@<%= follower.username %></div>
                <%= if follower.bio do %>
                  <p class="text-sm mt-1 line-clamp-2"><%= follower.bio %></p>
                <% end %>
              </div>
            </div>
            <%= if @current_user.id != follower.id do %>
              <%= if following?(@current_user, follower) do %>
                <button
                  phx-click="unfollow"
                  phx-value-id={follower.id}
                  class="px-4 py-2 bg-black text-white dark:bg-white dark:text-black rounded-full font-bold hover:opacity-80"
                >
                  Following
                </button>
              <% else %>
                <button
                  phx-click="follow"
                  phx-value-id={follower.id}
                  class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-full font-bold hover:bg-gray-100 dark:hover:bg-gray-800"
                >
                  Follow
                </button>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp following?(current_user, other_user) do
    Social.following?(current_user.id, other_user.id)
  end
end
