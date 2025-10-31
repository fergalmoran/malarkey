defmodule MalarkeyWeb.Components.Media do
  @moduledoc """
  Media display components for posts.
  """
  use Phoenix.Component

  attr :media_urls, :list, required: true
  attr :media_types, :list, default: []
  attr :class, :string, default: nil

  def post_media(assigns) do
    ~H"""
    <div :if={length(@media_urls) > 0} class={["mt-3 rounded-xl overflow-hidden", @class]}>
      <%= if length(@media_urls) == 1 do %>
        <.single_media url={Enum.at(@media_urls, 0)} type={Enum.at(@media_types, 0)} />
      <% else %>
        <.media_grid media_urls={@media_urls} media_types={@media_types} />
      <% end %>
    </div>
    """
  end

  attr :url, :string, required: true
  attr :type, :string, default: "image"

  defp single_media(assigns) do
    ~H"""
    <%= case @type do %>
      <% "video" -> %>
        <video controls class="w-full max-h-[500px] bg-black">
          <source src={@url} type="video/mp4" />
          Your browser does not support the video tag.
        </video>
      <% "gif" -> %>
        <img src={@url} alt="GIF" class="w-full max-h-[500px] object-contain bg-muted" />
      <% _ -> %>
        <img src={@url} alt="Post media" class="w-full max-h-[500px] object-cover" />
    <% end %>
    """
  end

  attr :media_urls, :list, required: true
  attr :media_types, :list, required: true

  defp media_grid(assigns) do
    assigns = assign(assigns, :media_count, length(assigns.media_urls))

    ~H"""
    <div class={[
      "grid gap-0.5",
      @media_count == 2 && "grid-cols-2",
      @media_count == 3 && "grid-cols-2",
      @media_count >= 4 && "grid-cols-2"
    ]}>
      <%= for {url, index} <- Enum.with_index(@media_urls) do %>
        <%= if index < 4 do %>
          <div class={[
            "relative aspect-video overflow-hidden bg-muted",
            @media_count == 3 && index == 0 && "row-span-2"
          ]}>
            <%= if Enum.at(@media_types, index) == "video" do %>
              <video controls class="w-full h-full object-cover">
                <source src={url} type="video/mp4" />
              </video>
            <% else %>
              <img src={url} alt={"Media #{index + 1}"} class="w-full h-full object-cover" />
            <% end %>
            <%= if @media_count > 4 && index == 3 do %>
              <div class="absolute inset-0 bg-black/60 flex items-center justify-center">
                <span class="text-white text-3xl font-bold">+<%= @media_count - 4 %></span>
              </div>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
