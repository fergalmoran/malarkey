defmodule RobotterWeb.PostLive.PostComponent do
  use RobotterWeb, :live_component
  alias Robotter.Timeline
  alias Robotter.Timeline.Post

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto my-6">
      <article class="flex flex-wrap items-start p-2 border-t border-b border-gray-400 cursor-pointer hover:bg-gray-100">
        <img
          src="https://joeschmoe.io/api/v1/random?q=#{@post.id}"
          class="w-12 h-12 mr-3 rounded-full"
        />

        <div class="flex flex-wrap items-start justify-start flex-1">
          <div class="flex items-center flex-1">
            <div class="flex items-center flex-1">
              <h3 class="mr-2 font-bold hover:underline">
                <a href="#"><%= @post.fullname %></a>
              </h3>
              <span class="mr-2">
                <svg
                  class="w-4 h-4"
                  fill="#1da1f2"
                  viewBox="0 0 24 24"
                  aria-label="Verified account"
                  class=""
                >
                  <g>
                    <path d="M22.5 12.5c0-1.58-.875-2.95-2.148-3.6.154-.435.238-.905.238-1.4 0-2.21-1.71-3.998-3.818-3.998-.47 0-.92.084-1.336.25C14.818 2.415 13.51 1.5 12 1.5s-2.816.917-3.437 2.25c-.415-.165-.866-.25-1.336-.25-2.11 0-3.818 1.79-3.818 4 0 .494.083.964.237 1.4-1.272.65-2.147 2.018-2.147 3.6 0 1.495.782 2.798 1.942 3.486-.02.17-.032.34-.032.514 0 2.21 1.708 4 3.818 4 .47 0 .92-.086 1.335-.25.62 1.334 1.926 2.25 3.437 2.25 1.512 0 2.818-.916 3.437-2.25.415.163.865.248 1.336.248 2.11 0 3.818-1.79 3.818-4 0-.174-.012-.344-.033-.513 1.158-.687 1.943-1.99 1.943-3.484zm-6.616-3.334l-4.334 6.5c-.145.217-.382.334-.625.334-.143 0-.288-.04-.416-.126l-.115-.094-2.415-2.415c-.293-.293-.293-.768 0-1.06s.768-.294 1.06 0l1.77 1.767 3.825-5.74c.23-.345.696-.436 1.04-.207.346.23.44.696.21 1.04z">
                    </path>
                  </g>
                </svg>
              </span>
              <span class="mr-1 text-sm text-gray-600">@<%= @post.username %></span>
              <span class="mr-1 text-sm text-gray-600">·</span>
              <span class="text-sm text-gray-600">Apr 7</span>
            </div>
            <div class="text-gray-600">
              <a
                href="#"
                class="flex items-center justify-center w-6 h-6 bg-transparent rounded-full hover:bg-blue-200 hover:text-blue-600"
              >
                <svg viewBox="0 0 24 24" class="w-3 h-3 fill-current">
                  <g>
                    <path d="M20.207 8.147c-.39-.39-1.023-.39-1.414 0L12 14.94 5.207 8.147c-.39-.39-1.023-.39-1.414 0-.39.39-.39 1.023 0 1.414l7.5 7.5c.195.196.45.294.707.294s.512-.098.707-.293l7.5-7.5c.39-.39.39-1.022 0-1.413z">
                    </path>
                  </g>
                </svg>
              </a>
            </div>
          </div>

          <div class="w-full">
            <p class="my-1"><%= @post.body %></p>
            <%= if false do %>
              <div class="rounded-lg">
                <img
                  src="https://www.fillmurray.com/640/360"
                  class="object-cover w-full h-64 border rounded-lg"
                />
              </div>
            <% end %>

            <div class="flex items-center justify-between py-2">
              <div class="flex items-center mr-8 text-gray-600 hover:text-blue-500">
                <a
                  href="#"
                  class="flex items-center justify-center w-8 h-8 rounded-full hover:bg-blue-200 hover:text-blue-500"
                >
                  <%= Heroicons.icon("chat-bubble-oval-left", type: "outline", class: "w-5 h-5") %>
                </a>
                <span class="ml-1">1.5K</span>
              </div>

              <div class="flex items-center mr-8 text-gray-600 hover:text-green-500">
                <a
                  href="#"
                  class="flex items-center justify-center w-8 h-8 rounded-full hover:bg-green-200 hover:text-green-500"
                >
                  <%= Heroicons.icon("arrow-path-rounded-square", type: "outline", class: "w-5 h-5") %>
                </a>
                <span class="ml-1">6.7K</span>
              </div>

              <div class="flex items-center mr-6 text-gray-600 hover:text-red-500">
                <a
                  href="#"
                  class="flex items-center justify-center w-8 h-8 rounded-full hover:bg-red-200 hover:text-red-500"
                >
                  <%= Heroicons.icon("heart", type: "outline", class: "w-5 h-5") %>
                </a>
                <span class="ml-1">99.9K</span>
              </div>

              <div class="flex items-center mr-6 text-gray-600 hover:text-red-500 pull">
                <.link patch={~p"/posts/#{@post}/edit"}>
                  <%= Heroicons.icon("pencil-square", type: "outline", class: "w-5 h-5") %>
                </.link>
              </div>
            </div>
          </div>
        </div>
      </article>
    </div>
    """
  end
end
