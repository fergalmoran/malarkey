defmodule MalarkeyWeb.Components.PostComposer do
  @moduledoc """
  Reusable post composer component for creating new posts and replies.
  """
  use Phoenix.Component
  import MalarkeyWeb.Components.UI
  import MalarkeyWeb.Components.Avatar

  attr :current_user, :map, required: true
  attr :body, :string, default: ""
  attr :char_count, :integer, default: 0
  attr :uploaded_files, :list, default: []
  attr :uploads, :map, required: true
  attr :submit_event, :string, required: true
  attr :update_event, :string, required: true
  attr :placeholder, :string, default: "What's happening?"
  attr :reply_to, :map, default: nil
  attr :show_cancel, :boolean, default: false
  attr :cancel_event, :string, default: nil

  def post_composer(assigns) do
    # Generate unique IDs based on whether it's a reply or not
    assigns = assign(assigns, :form_id, if(assigns.reply_to, do: "reply-composer-form", else: "post-composer-form"))
    assigns = assign(assigns, :textarea_id, if(assigns.reply_to, do: "reply-textarea", else: "post-textarea"))
    
    ~H"""
    <div class="flex space-x-3">
      <div class="flex-shrink-0">
        <.avatar user={@current_user} size="lg" />
      </div>
      <div class="flex-1">
        <!-- Reply context -->
        <div :if={@reply_to} class="mb-2 text-sm text-muted-foreground">
          Replying to <span class="text-primary">@<%= @reply_to.user.username %></span>
        </div>

        <form id={@form_id} phx-submit={@submit_event}>
          <textarea
            name="body"
            phx-keyup={@update_event}
            phx-hook="PasteImage"
            id={@textarea_id}
            placeholder={@placeholder}
            rows="3"
            class="flex min-h-[60px] w-full border-0 bg-transparent px-0 py-0 text-lg placeholder:text-muted-foreground focus:outline-none focus-visible:outline-none focus:ring-0 resize-none"
          ><%= @body %></textarea>

          <!-- Media Previews -->
          <div :if={length(@uploaded_files) > 0 || length(@uploads.media.entries) > 0} class="grid grid-cols-2 gap-2 mt-3">
            <!-- Uploaded files (GIFs, pasted images) -->
            <div
              :for={{url, _type} <- Enum.with_index(@uploaded_files)}
              class="relative overflow-hidden rounded-lg aspect-video bg-muted"
            >
              <img src={elem(url, 0)} alt="Preview" class="object-cover w-full h-full" />
              <button
                type="button"
                phx-click="remove_media"
                phx-value-index={elem(url, 1)}
                class="absolute top-2 right-2 p-1.5 bg-black/60 hover:bg-black/80 rounded-full text-white"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
            <!-- LiveView uploads -->
            <div
              :for={entry <- @uploads.media.entries}
              class="relative overflow-hidden rounded-lg aspect-video bg-muted"
            >
              <.live_img_preview entry={entry} class="object-cover w-full h-full" />
              <button
                type="button"
                phx-click="remove_upload"
                phx-value-ref={entry.ref}
                class="absolute top-2 right-2 p-1.5 bg-black/60 hover:bg-black/80 rounded-full text-white"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
          </div>

          <div class="flex items-center justify-between mt-3">
            <div class="relative flex items-center space-x-1">
              <!-- Image/Video Upload -->
              <label class="flex items-center justify-center p-2 transition-colors rounded-full cursor-pointer hover:bg-accent text-primary">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                  />
                </svg>
                <.live_file_input upload={@uploads.media} class="hidden" />
              </label>

              <!-- GIF Button -->
              <button
                type="button"
                phx-click="open_giphy"
                class="flex items-center justify-center p-2 transition-colors rounded-full hover:bg-accent text-primary"
              >
                <span class="text-sm font-bold">GIF</span>
              </button>

              <!-- Emoji Button -->
              <button
                type="button"
                phx-click="toggle_emoji_picker"
                class="flex items-center justify-center p-2 transition-colors rounded-full hover:bg-accent text-primary"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </button>
            </div>

            <div class="flex items-center gap-3">
              <span class={[
                "text-sm",
                @char_count > 280 && "text-destructive",
                @char_count <= 280 && "text-muted-foreground"
              ]}>
                <%= @char_count %> / 280
              </span>

              <button
                :if={@show_cancel}
                type="button"
                phx-click={@cancel_event}
                class="px-4 py-2 text-sm font-medium transition-colors rounded-md hover:bg-muted"
              >
                Cancel
              </button>

              <.ui_button type="submit" disabled={@char_count == 0 || @char_count > 280}>
                Post
              </.ui_button>
            </div>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
