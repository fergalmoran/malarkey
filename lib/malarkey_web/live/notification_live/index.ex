defmodule MalarkeyWeb.NotificationLive.Index do
  use MalarkeyWeb, :live_view

  import MalarkeyWeb.Components.UI

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Notifications")
     |> assign(:notifications, [])}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <div class="border-b border-gray-200 dark:border-gray-700 p-4">
        <h1 class="text-xl font-bold">Notifications</h1>
      </div>

      <div class="p-8 text-center text-gray-500">
        <svg
          class="w-16 h-16 mx-auto mb-4"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
          />
        </svg>
        <p>No notifications yet</p>
        <p class="text-sm mt-2">
          When someone likes, reposts, or replies to your posts, you'll see it here.
        </p>
      </div>
    </div>
    """
  end
end
