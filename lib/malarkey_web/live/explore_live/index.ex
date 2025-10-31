defmodule MalarkeyWeb.ExploreLive.Index do
  use MalarkeyWeb, :live_view

  import MalarkeyWeb.Components.UI

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Explore")
     |> assign(:search_query, "")}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, assign(socket, :search_query, query)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <div class="border-b border-gray-200 dark:border-gray-700 p-4">
        <h1 class="text-xl font-bold">Explore</h1>
      </div>

      <div class="p-4">
        <input
          type="text"
          placeholder="Search Malarkey"
          value={@search_query}
          phx-change="search"
          class="w-full px-4 py-3 rounded-full bg-gray-100 dark:bg-gray-800 border-none focus:ring-2 focus:ring-blue-500"
        />
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
            d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
          />
        </svg>
        <p>Try searching for people, topics, or keywords</p>
      </div>
    </div>
    """
  end
end
