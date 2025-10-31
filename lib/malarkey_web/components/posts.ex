defmodule MalarkeyWeb.Components.Posts do
  @moduledoc """
  Reusable post display components.
  """
  use Phoenix.Component
  import MalarkeyWeb.Components.UI
  import MalarkeyWeb.Components.Media
  import MalarkeyWeb.Components.Avatar

  alias Malarkey.Social

  # Import for verified routes
  use MalarkeyWeb, :verified_routes

  attr :post, :map, required: true
  attr :current_user, :map, required: true
  attr :dom_id, :string, default: nil
  attr :class, :string, default: nil

  def post_card(assigns) do
    assigns = assign(assigns, :card_class, Enum.join(["transition-all duration-300 ease-out hover:shadow-md animate-slide-in cursor-pointer", assigns[:class] || ""], " "))

    ~H"""
    <.ui_card
      id={@dom_id}
      class={@card_class}
      phx-hook="PostCard"
      data-post-url={~p"/posts/#{@post.id}"}
    >
      <.ui_card_content class="pt-6">
        <div class="flex space-x-3">
          <div class="flex-shrink-0">
            <.link navigate={~p"/#{@post.user.username}"} class="block transition-opacity hover:opacity-80">
              <.avatar user={@post.user} size="lg" />
            </.link>
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex flex-wrap items-center gap-2">
              <.link navigate={~p"/#{@post.user.username}"} class="font-semibold transition-colors text-foreground hover:underline">
                <%= @post.user.display_name || @post.user.username %>
              </.link>
              <.link navigate={~p"/#{@post.user.username}"} class="transition-colors text-muted-foreground hover:underline">
                @<%= @post.user.username %>
              </.link>
              <span class="text-muted-foreground">·</span>
              <span class="text-sm text-muted-foreground">
                <%= Timex.format!(@post.inserted_at, "{relative}", :relative) %>
              </span>
            </div>
            <p :if={@post.body && String.trim(@post.body) != "" && String.trim(@post.body) != " "} class="mt-2 whitespace-pre-wrap text-foreground">
              <%= @post.body %>
            </p>

            <!-- Media Display -->
            <.post_media
              :if={length(@post.media_urls || []) > 0}
              media_urls={@post.media_urls}
              media_types={@post.media_types || []}
            />
          </div>
        </div>
      </.ui_card_content>

        <!-- Post Actions - outside the link -->
        <div class="flex items-center gap-6 mt-4 px-4 pb-2">
          <.ui_button
            variant="ghost"
            size="sm"
            phx-click="open_reply_modal"
            phx-value-id={@post.id}
            class="gap-2 text-muted-foreground hover:text-primary"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
              />
            </svg>
            <span><%= @post.replies_count %></span>
          </.ui_button>

          <.ui_button
            variant="ghost"
            size="sm"
            phx-click={
              if reposted_by_user?(@post, @current_user),
                do: "delete_repost",
                else: "repost"
            }
            phx-value-id={@post.id}
            class={[
              "gap-2",
              reposted_by_user?(@post, @current_user) && "text-green-600",
              !reposted_by_user?(@post, @current_user) && "text-muted-foreground hover:text-green-600"
            ]}
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
            <span><%= @post.reposts_count %></span>
          </.ui_button>

          <.ui_button
            variant="ghost"
            size="sm"
            phx-click={
              if liked_by_user?(@post, @current_user),
                do: "unlike_post",
                else: "like_post"
            }
            phx-value-id={@post.id}
            class={[
              "gap-2",
              liked_by_user?(@post, @current_user) && "text-red-500 hover:text-red-600",
              !liked_by_user?(@post, @current_user) &&
                "text-muted-foreground hover:text-red-500"
            ]}
          >
            <svg
              class={[
                "w-4 h-4",
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
            <span><%= @post.likes_count %></span>
          </.ui_button>

          <.ui_button variant="ghost" size="sm" class="text-muted-foreground hover:text-primary">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z"
              />
            </svg>
          </.ui_button>

          <.ui_button
            :if={@post.user_id == @current_user.id}
            variant="ghost"
            size="sm"
            phx-click="delete_post"
            phx-value-id={@post.id}
            data-confirm="Are you sure you want to delete this post?"
            class="text-muted-foreground hover:text-destructive"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
              />
            </svg>
          </.ui_button>
        </div>
    </.ui_card>
    """
  end

  attr :reply, :map, required: true
  attr :current_user, :map, required: true
  attr :level, :integer, default: 0
  attr :parent_post, :map, default: nil

  def threaded_reply(assigns) do
    ~H"""
    <div class={[
      "relative",
      @level > 0 && "ml-12"
    ]}>
      <!-- Thread line connector -->
      <div :if={@level > 0} class="absolute left-0 top-0 bottom-0 w-px bg-gray-200 dark:bg-gray-700 -ml-6"></div>

      <div class="flex space-x-3 py-3">
        <div class="flex-shrink-0">
          <.link navigate={~p"/#{@reply.user.username}"} class="block transition-opacity hover:opacity-80">
            <.avatar user={@reply.user} size="md" />
          </.link>
        </div>

        <div class="flex-1 min-w-0">
          <div class="flex flex-wrap items-center gap-2">
            <.link navigate={~p"/#{@reply.user.username}"} class="font-semibold transition-colors hover:underline">
              <%= @reply.user.display_name || @reply.user.username %>
            </.link>
            <.link navigate={~p"/#{@reply.user.username}"} class="text-gray-500 transition-colors hover:underline">
              @<%= @reply.user.username %>
            </.link>
            <span class="text-gray-500">·</span>
            <span class="text-sm text-gray-500">
              <%= Timex.format!(@reply.inserted_at, "{relative}", :relative) %>
            </span>
          </div>

          <div :if={@parent_post} class="text-sm text-gray-500 mt-1">
            Replying to <.link navigate={~p"/#{@parent_post.user.username}"} class="text-blue-500 hover:underline">@<%= @parent_post.user.username %></.link>
          </div>

          <p :if={@reply.body && String.trim(@reply.body) != "" && String.trim(@reply.body) != " "} class="mt-2 whitespace-pre-wrap">
            <%= @reply.body %>
          </p>

          <!-- Reply Actions -->
          <div class="flex items-center gap-6 mt-3">
            <.ui_button
              variant="ghost"
              size="sm"
              phx-click="open_reply_modal"
              phx-value-id={@reply.id}
              class="gap-2 text-gray-500 hover:text-blue-500"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                />
              </svg>
              <span><%= @reply.replies_count %></span>
            </.ui_button>

            <.ui_button
              variant="ghost"
              size="sm"
              phx-click={if liked_by_user?(@reply, @current_user), do: "unlike_post", else: "like_post"}
              phx-value-id={@reply.id}
              class={[
                "gap-2",
                liked_by_user?(@reply, @current_user) && "text-red-500 hover:text-red-600",
                !liked_by_user?(@reply, @current_user) && "text-gray-500 hover:text-red-500"
              ]}
            >
              <svg
                class={["w-4 h-4", liked_by_user?(@reply, @current_user) && "fill-current"]}
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
              <span><%= @reply.likes_count %></span>
            </.ui_button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions that need to be available
  defp reposted_by_user?(post, user) do
    Social.reposted_by_user?(user.id, post.id)
  end

  defp liked_by_user?(post, user) do
    Social.liked_by_user?(user.id, post.id)
  end
end
