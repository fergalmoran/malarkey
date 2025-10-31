defmodule MalarkeyWeb.PostLive.Show do
  use MalarkeyWeb, :live_view

  import MalarkeyWeb.Components.UI

  alias Malarkey.Social
  import MalarkeyWeb.Components.Posts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Social.get_post(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Post not found")
         |> push_navigate(to: ~p"/")}

      post ->
        threaded_replies = Social.get_threaded_replies(id)
        direct_replies = Map.get(threaded_replies, post.id, [])

        if connected?(socket) do
          Phoenix.PubSub.subscribe(Malarkey.PubSub, "post:#{id}")
        end

        {:ok,
         socket
         |> assign(:post, post)
         |> assign(:page_title, "Post")
         |> assign(:reply_content, "")
         |> assign(:char_count, 0)
         |> assign(:threaded_replies, threaded_replies)
         |> assign(:direct_replies, direct_replies)}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("update_reply", %{"reply_content" => content}, socket) do
    char_count = String.length(content)
    {:noreply, assign(socket, reply_content: content, char_count: char_count)}
  end

  @impl true
  def handle_event("post_reply", _, socket) do
    attrs = %{
      body: socket.assigns.reply_content,
      user_id: socket.assigns.current_user.id,
      reply_to_id: socket.assigns.post.id
    }

    case Social.create_post(attrs) do
      {:ok, _reply} ->
        # Reload threaded replies
        threaded_replies = Social.get_threaded_replies(socket.assigns.post.id)
        direct_replies = Map.get(threaded_replies, socket.assigns.post.id, [])
        updated_post = Social.get_post!(socket.assigns.post.id)

        {:noreply,
         socket
         |> put_flash(:info, "Reply posted successfully")
         |> assign(reply_content: "", char_count: 0)
         |> assign(:threaded_replies, threaded_replies)
         |> assign(:direct_replies, direct_replies)
         |> assign(:post, updated_post)}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = changeset_errors(changeset)
        {:noreply, put_flash(socket, :error, "Failed to post reply: #{errors}")}
    end
  end

  @impl true
  def handle_event("like_post", %{"id" => id}, socket) do
    case Social.create_like(%{user_id: socket.assigns.current_user.id, post_id: id}) do
      {:ok, _like} ->
        updated_post = Social.get_post!(id)
        {:noreply, assign(socket, :post, updated_post)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to like post")}
    end
  end

  @impl true
  def handle_event("unlike_post", %{"id" => id}, socket) do
    case Social.delete_like(socket.assigns.current_user.id, id) do
      {:ok, _} ->
        updated_post = Social.get_post!(id)
        {:noreply, assign(socket, :post, updated_post)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to unlike post")}
    end
  end

  @impl true
  def handle_event("repost", %{"id" => id}, socket) do
    case Social.create_repost(socket.assigns.current_user.id, id) do
      {:ok, _repost} ->
        {:noreply, put_flash(socket, :info, "Reposted successfully")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to repost")}
    end
  end

  @impl true
  def handle_event("delete_repost", %{"id" => id}, socket) do
    case Social.delete_repost(socket.assigns.current_user.id, id) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Repost removed")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove repost")}
    end
  end

  @impl true
  def handle_info({:like_added, _like}, socket) do
    updated_post = Social.get_post!(socket.assigns.post.id)
    {:noreply, assign(socket, :post, updated_post)}
  end

  def handle_info({:like_removed, _like}, socket) do
    updated_post = Social.get_post!(socket.assigns.post.id)
    {:noreply, assign(socket, :post, updated_post)}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <div class="border-b border-gray-200 dark:border-gray-700 p-4">
        <.link navigate={~p"/"} class="text-blue-500 hover:underline">
          ← Back to Timeline
        </.link>
      </div>

      <!-- Main Post -->
      <div class="border-b border-gray-200 dark:border-gray-700 p-4">
        <div class="flex space-x-3">
          <div class="flex-shrink-0">
            <.avatar user={@post.user} size="lg" />
          </div>
          <div class="flex-1">
            <div class="flex items-center space-x-1">
              <span class="font-bold">
                <%= @post.user.display_name || @post.user.username %>
              </span>
              <span class="text-gray-500">@<%= @post.user.username %></span>
            </div>
          </div>
        </div>

        <div class="mt-3">
          <p class="text-xl whitespace-pre-wrap"><%= @post.body %></p>
        </div>

        <div class="mt-3 text-gray-500 text-sm">
          <%= Timex.format!(@post.inserted_at, "{h12}:{m} {AM} · {Mshort} {D}, {YYYY}") %>
        </div>

        <!-- Post Stats -->
        <div class="flex items-center space-x-4 mt-3 pt-3 border-t border-gray-200 dark:border-gray-700">
          <div>
            <span class="font-bold"><%= @post.reposts_count %></span>
            <span class="text-gray-500"> Reposts</span>
          </div>
          <div>
            <span class="font-bold"><%= @post.likes_count %></span>
            <span class="text-gray-500"> Likes</span>
          </div>
        </div>

        <!-- Post Actions -->
        <div class="flex items-center justify-around mt-3 pt-3 border-t border-gray-200 dark:border-gray-700">
          <button class="text-gray-500 hover:text-blue-500 p-2">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
              />
            </svg>
          </button>

          <button
            phx-click={
              if @post.user_id == @current_user.id, do: "delete_repost", else: "repost"
            }
            phx-value-id={@post.id}
            class="text-gray-500 hover:text-green-500 p-2"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
          </button>

          <button
            phx-click={
              if liked_by_user?(@post, @current_user), do: "unlike_post", else: "like_post"
            }
            phx-value-id={@post.id}
            class={[
              "p-2",
              liked_by_user?(@post, @current_user) && "text-red-500",
              !liked_by_user?(@post, @current_user) && "text-gray-500 hover:text-red-500"
            ]}
          >
            <svg
              class={[
                "w-6 h-6",
                liked_by_user?(@post, @current_user) && "fill-current"
              ]}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
              />
            </svg>
          </button>

          <button class="text-gray-500 hover:text-blue-500 p-2">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z"
              />
            </svg>
          </button>
        </div>
      </div>

      <!-- Reply Composer -->
      <div class="border-b border-gray-200 dark:border-gray-700 p-4">
        <div class="flex space-x-3">
          <div class="flex-shrink-0">
            <.avatar user={@current_user} size="lg" />
          </div>
          <div class="flex-1">
            <textarea
              phx-keyup="update_reply"
              name="reply_content"
              class="w-full border-none focus:ring-0 resize-none text-lg"
              placeholder="Post your reply"
              rows="3"
            ><%= @reply_content %></textarea>
            <div class="flex items-center justify-between mt-3">
              <div class="flex space-x-2">
                <!-- Media upload buttons would go here -->
              </div>
              <div class="flex items-center space-x-3">
                <span class={[
                  "text-sm",
                  @char_count > 280 && "text-red-500",
                  @char_count > 260 && @char_count <= 280 && "text-yellow-500",
                  @char_count <= 260 && "text-gray-500"
                ]}>
                  <%= if @char_count > 0, do: "#{@char_count}/280", else: "" %>
                </span>
                <button
                  phx-click="post_reply"
                  disabled={@char_count == 0 || @char_count > 280}
                  class="px-4 py-2 bg-blue-500 text-white rounded-full font-bold hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Reply
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Replies -->
      <div id="replies" class="divide-y divide-gray-200 dark:divide-gray-700">
        <%= for reply <- @direct_replies do %>
          <div class="p-4">
            <.threaded_reply
              reply={reply}
              current_user={@current_user}
              level={0}
              parent_post={@post}
            />
            <%= render_nested_replies(assigns, reply, 1) %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_nested_replies(assigns, parent_reply, level) do
    replies = Map.get(assigns.threaded_replies, parent_reply.id, [])

    assigns = assign(assigns, :nested_replies, replies)
    assigns = assign(assigns, :level, level)
    assigns = assign(assigns, :parent_reply, parent_reply)

    ~H"""
    <%= for reply <- @nested_replies do %>
      <.threaded_reply
        reply={reply}
        current_user={@current_user}
        level={@level}
        parent_post={@parent_reply}
      />
      <%= render_nested_replies(assigns, reply, @level + 1) %>
    <% end %>
    """
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

  defp liked_by_user?(post, user) do
    Social.liked_by_user?(user.id, post.id)
  end
end
