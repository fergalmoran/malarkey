defmodule MalarkeyWeb.PostLive.Index do
  use MalarkeyWeb, :live_view
  require Logger
  alias Malarkey.Timeline
  alias Malarkey.Timeline.Post
  on_mount MalarkeyWeb.UserLiveAuth

  @impl true
  @spec mount(any, any, Phoenix.LiveView.Socket.t()) ::
          {:ok, map, [{:temporary_assigns, [...]}, ...]}
  def mount(_params, _session, socket) do
    if connected?(socket), do: Timeline.subscribe()
    {:ok, assign(socket, :posts, list_posts()), temporary_assigns: [posts: []]}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :like, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, Timeline.get_post!(id))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, Timeline.get_post!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "More Malarkey")
    |> assign(:post, %Post{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Posts")
    |> assign(:post, nil)
  end

  @impl true
  def handle_event("like", %{"id" => id}, socket) do
    post = Timeline.get_post!(id)
    {:ok, _} = Timeline.add_like(socket.assigns.current_user, post)

    {:noreply, assign(socket, :posts, list_posts())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Timeline.get_post!(id)
    {:ok, _} = Timeline.delete_post(post)

    {:noreply, assign(socket, :posts, list_posts())}
  end

  @impl true
  def handle_info({:post_created, post}, socket) do
    {:noreply, update(socket, :posts, fn posts -> [post | posts] end)}
  end

  @impl true
  def handle_info({:post_updated, post}, socket) do
    {:noreply, update(socket, :posts, fn posts -> [post | posts] end)}
  end

  defp list_posts do
    Timeline.list_posts()
  end
end
