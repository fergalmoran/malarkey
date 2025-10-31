defmodule MalarkeyWeb.TimelineLive.Index do
  use MalarkeyWeb, :live_view

  import MalarkeyWeb.Components.UI
  import MalarkeyWeb.Components.Posts
  import MalarkeyWeb.Components.PostComposer

  alias Malarkey.{Social, Media, Giphy}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Malarkey.PubSub, "posts:new")
    end

    {:ok,
     socket
     |> assign(:page_title, "Home")
     |> assign(:composer_open, false)
    |> assign(:post_body, "")
     |> assign(:char_count, 0)
     |> assign(:uploaded_files, [])
     |> assign(:giphy_modal_open, false)
     |> assign(:giphy_search, "")
     |> assign(:giphy_results, [])
     |> assign(:giphy_loading, false)
     |> assign(:emoji_picker_open, false)
     |> assign(:emoji_category, "smileys")
     |> assign(:emoji_search, "")
     |> assign(:filtered_emojis, get_emoji_category("smileys"))
     |> assign(:reply_modal_open, false)
     |> assign(:reply_to_post, nil)
     |> assign(:reply_content, "")
     |> assign(:reply_char_count, 0)
     |> allow_upload(:media, accept: ~w(.jpg .jpeg .png .gif .mp4 .mov .webm), max_entries: 4, max_file_size: 50_000_000)
     |> stream(:posts, Social.list_timeline_posts(socket.assigns.current_user, limit: 50))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Home")
  end

  @impl true
  def handle_event("open_composer", _, socket) do
    {:noreply, assign(socket, composer_open: true)}
  end

  @impl true
  def handle_event("close_composer", _, socket) do
    {:noreply, assign(socket, composer_open: false, post_body: "", char_count: 0, uploaded_files: [], giphy_modal_open: false, emoji_picker_open: false, emoji_search: "", emoji_category: "smileys", filtered_emojis: get_emoji_category("smileys"))}
  end

  @impl true
  def handle_event("update_post", %{"value" => content}, socket) do
    char_count = String.length(content)
    {:noreply, assign(socket, post_body: content, char_count: char_count)}
  end

  def handle_event("update_post", _params, socket) do
    # Fallback in case event structure is different
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :media, ref)}
  end

  @impl true
  def handle_event("open_giphy", _, socket) do
    socket =
      socket
      |> assign(:giphy_modal_open, true)
      |> assign(:giphy_loading, true)

    send(self(), :load_trending_gifs)
    {:noreply, socket}
  end

  @impl true
  def handle_event("close_giphy", _, socket) do
    {:noreply, assign(socket, giphy_modal_open: false, giphy_search: "", giphy_results: [])}
  end

  @impl true
  def handle_event("search_giphy", %{"search" => query}, socket) do
    socket = assign(socket, giphy_search: query, giphy_loading: true)
    send(self(), {:search_giphy, query})
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_gif", %{"url" => url}, socket) do
    uploaded_files = socket.assigns.uploaded_files ++ [{url, "gif"}]

    {:noreply,
     socket
     |> assign(:uploaded_files, uploaded_files)
     |> assign(:giphy_modal_open, false)
     |> assign(:giphy_search, "")
     |> assign(:giphy_results, [])}
  end

  @impl true
  def handle_event("remove_media", %{"index" => index}, socket) do
    index = String.to_integer(index)
    uploaded_files = List.delete_at(socket.assigns.uploaded_files, index)
    {:noreply, assign(socket, :uploaded_files, uploaded_files)}
  end

  @impl true
  def handle_event("toggle_emoji_picker", _, socket) do
    is_open = !Map.get(socket.assigns, :emoji_picker_open, false)
    {:noreply, assign(socket, emoji_picker_open: is_open, emoji_search: "", emoji_category: "smileys", filtered_emojis: get_emoji_category("smileys"))}
  end

  @impl true
  def handle_event("insert_emoji", %{"emoji" => emoji}, socket) do
    updated_body = socket.assigns.post_body <> emoji
    char_count = String.length(updated_body)
    {:noreply, assign(socket, post_body: updated_body, char_count: char_count)}
  end

  @impl true
  def handle_event("change_emoji_category", %{"category" => category}, socket) do
    emojis = if socket.assigns.emoji_search != "", do: search_emojis(socket.assigns.emoji_search), else: get_emoji_category(category)
    {:noreply, assign(socket, emoji_category: category, filtered_emojis: emojis)}
  end

  @impl true
  def handle_event("search_emoji", %{"search" => search}, socket) do
    search = String.downcase(search)
    emojis = if search == "", do: get_emoji_category(socket.assigns.emoji_category), else: search_emojis(search)
    {:noreply, assign(socket, emoji_search: search, filtered_emojis: emojis)}
  end

  @impl true
  def handle_event("paste_image", %{"data" => data, "type" => type}, socket) do
    require Logger
    Logger.info("Received paste_image event with type: #{type}")

    try do
      # Extract base64 data
      [_prefix, base64] = String.split(data, ",", parts: 2)
      binary = Base.decode64!(base64)
      Logger.info("Decoded image binary, size: #{byte_size(binary)} bytes")

      case Media.upload_binary(binary, type, socket.assigns.current_user.id) do
        {:ok, url} ->
          Logger.info("Successfully uploaded to S3: #{url}")
          media_type = Media.get_media_type(type)
          uploaded_files = socket.assigns.uploaded_files ++ [{url, media_type}]
          {:noreply,
           socket
           |> assign(:uploaded_files, uploaded_files)
           |> put_flash(:info, "Image pasted successfully!")}

        {:error, reason} ->
          Logger.error("Failed to upload pasted image: #{inspect(reason)}")
          {:noreply, put_flash(socket, :error, "Failed to upload pasted image. Please check AWS S3 configuration.")}
      end
    rescue
      e ->
        Logger.error("Error processing pasted image: #{inspect(e)}")
        {:noreply, put_flash(socket, :error, "Error processing pasted image: #{Exception.message(e)}")}
    end
  end


  @impl true
  def handle_event("post_post", params, socket) do
    # Accept both "body" and "content" for legacy/new posts
    body = Map.get(params, "body") || Map.get(params, "content") || ""

    # Upload any pending files
    media_urls =
      consume_uploaded_entries(socket, :media, fn %{path: path}, entry ->
        content_type = entry.client_type
        user_id = socket.assigns.current_user.id

        case Media.upload_file(path, content_type, user_id) do
          {:ok, url} -> {:ok, url}
          {:error, _} -> {:postpone, :error}
        end
      end)

    # Add any GIFs or pasted images
    all_media = media_urls ++ Enum.map(socket.assigns.uploaded_files, fn {url, _type} -> url end)
    media_types = Enum.map(socket.assigns.uploaded_files, fn {_url, type} -> type end)

    safe_body =
      case body do
        nil -> ""
        b when is_binary(b) -> String.trim(b)
        _ -> ""
      end

    # If media is present and body is empty, set body to a single space to satisfy NOT NULL constraint
    safe_body =
      if safe_body == "" and all_media != [] do
        " "
      else
        safe_body
      end

    post_attrs = %{
      body: safe_body,
      user_id: socket.assigns.current_user.id,
      media_urls: all_media,
      media_types: media_types
    }

    case Social.create_post(post_attrs) do
      {:ok, post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post posted successfully")
         |> assign(composer_open: false, post_body: "", char_count: 0, uploaded_files: [])
         |> stream_insert(:posts, post, at: 0)}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = changeset_errors(changeset)
        {:noreply, put_flash(socket, :error, "Failed to post post: #{errors}")}
    end
  end

  @impl true
  def handle_event("like_post", %{"id" => id}, socket) do
    case Social.create_like(%{user_id: socket.assigns.current_user.id, post_id: id}) do
      {:ok, _like} ->
        updated_post = Social.get_post!(id)
        {:noreply, stream_insert(socket, :posts, updated_post)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to like post")}
    end
  end

  @impl true
  def handle_event("unlike_post", %{"id" => id}, socket) do
    case Social.delete_like(socket.assigns.current_user.id, id) do
      {:ok, _} ->
        updated_post = Social.get_post!(id)
        {:noreply, stream_insert(socket, :posts, updated_post)}

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
  def handle_event("navigate", %{"url" => url}, socket) do
    {:noreply, push_navigate(socket, to: url)}
  end

  @impl true
  def handle_event("open_reply_modal", %{"id" => id}, socket) do
    post = Social.get_post!(id)
    {:noreply, assign(socket, reply_modal_open: true, reply_to_post: post, reply_content: "", reply_char_count: 0)}
  end

  @impl true
  def handle_event("close_reply_modal", _, socket) do
    {:noreply, assign(socket, reply_modal_open: false, reply_to_post: nil, reply_content: "", reply_char_count: 0)}
  end

  @impl true
  def handle_event("stop_propagation", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("update_reply", %{"value" => content}, socket) do
    char_count = String.length(content)
    {:noreply, assign(socket, reply_content: content, reply_char_count: char_count)}
  end

  @impl true
  def handle_event("post_reply", _, socket) do
    attrs = %{
      body: socket.assigns.reply_content,
      user_id: socket.assigns.current_user.id,
      reply_to_id: socket.assigns.reply_to_post.id
    }

    case Social.create_post(attrs) do
      {:ok, _reply} ->
        # Update the parent post in the stream to reflect new reply count
        updated_post = Social.get_post!(socket.assigns.reply_to_post.id)
        
        {:noreply,
         socket
         |> put_flash(:info, "Reply posted successfully")
         |> assign(reply_modal_open: false, reply_to_post: nil, reply_content: "", reply_char_count: 0)
         |> stream_insert(:posts, updated_post)}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = changeset_errors(changeset)
        {:noreply, put_flash(socket, :error, "Failed to post reply: #{errors}")}
    end
  end

  @impl true
  def handle_event("delete_post", %{"id" => id}, socket) do
    post = Social.get_post!(id)

    # Only allow the post owner to delete
    if post.user_id == socket.assigns.current_user.id do
      case Social.delete_post(post) do
        {:ok, _} ->
          # Send event to trigger animation, then wait before removing from stream
          send(self(), {:remove_post_from_stream, post})

          {:noreply,
           socket
           |> put_flash(:info, "Post deleted successfully")
           |> push_event("delete-post", %{id: "posts-#{post.id}"})}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete post")}
      end
    else
      {:noreply, put_flash(socket, :error, "You can only delete your own posts")}
    end
  end

  @impl true
  def handle_info({:remove_post_from_stream, post}, socket) do
    # Delay to allow animation to complete
    Process.sleep(300)
    {:noreply, stream_delete(socket, :posts, post)}
  end

  @impl true
  def handle_info(:load_trending_gifs, socket) do
    case Giphy.trending(25) do
      {:ok, gifs} ->
        {:noreply, assign(socket, giphy_results: gifs, giphy_loading: false)}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(giphy_loading: false)
         |> put_flash(:error, "Failed to load GIFs")}
    end
  end

  @impl true
  def handle_info({:search_giphy, query}, socket) do
    case Giphy.search(query, 25) do
      {:ok, gifs} ->
        {:noreply, assign(socket, giphy_results: gifs, giphy_loading: false)}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(giphy_loading: false)
         |> put_flash(:error, "Failed to search GIFs")}
    end
  end

  @impl true
  def handle_info({:new_post, post}, socket) do
    {:noreply, stream_insert(socket, :posts, post, at: 0)}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # Emoji helper functions
  defp get_all_emojis do
    %{
      "smileys" => ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "😚", "😙", "😋", "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔", "🤐", "🤨", "😐", "😑", "😶", "😏", "😒", "🙄", "😬", "🤥", "😌", "😔", "😪", "🤤", "😴"],
      "emotions" => ["😷", "🤒", "🤕", "🤢", "🤮", "🤧", "🥵", "🥶", "🥴", "😵", "🤯", "🤠", "🥳", "😎", "🤓", "🧐", "😕", "😟", "🙁", "☹️", "😮", "😯", "😲", "😳", "🥺", "😦", "😧", "😨", "😰", "😥", "😢", "😭", "😱", "😖", "😣", "😞", "😓", "😩", "😫", "🥱", "😤", "😡", "😠", "🤬"],
      "people" => ["👶", "👧", "🧒", "👦", "👩", "🧑", "👨", "👩‍🦱", "🧑‍🦱", "👨‍🦱", "👩‍🦰", "🧑‍🦰", "👨‍🦰", "👱‍♀️", "👱", "👱‍♂️", "👩‍🦳", "🧑‍🦳", "👨‍🦳", "👩‍🦲", "🧑‍🦲", "👨‍🦲", "🧔", "👵", "🧓", "👴", "👲", "👳‍♀️", "👳", "👳‍♂️", "🧕", "👮‍♀️", "👮", "👮‍♂️", "👷‍♀️", "👷", "👷‍♂️", "💂‍♀️", "💂", "💂‍♂️"],
      "gestures" => ["👍", "👎", "👊", "✊", "🤛", "🤜", "🤞", "✌️", "🤟", "🤘", "👌", "🤌", "🤏", "👈", "👉", "👆", "👇", "☝️", "✋", "🤚", "🖐️", "🖖", "👋", "🤙", "💪", "🦾", "🖕", "✍️", "🙏", "🦶", "🦵", "🦿", "👄", "🦷", "👅", "👂", "🦻", "👃", "👣", "👁️", "👀", "🧠", "🫀", "🫁", "🦴"],
      "animals" => ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐽", "🐸", "🐵", "🙈", "🙉", "🙊", "🐒", "🐔", "🐧", "🐦", "🐤", "🐣", "🐥", "🦆", "🦅", "🦉", "🦇", "🐺", "🐗", "🐴", "🦄", "🐝", "🐛", "🦋", "🐌", "🐞", "🐜", "🦟", "🦗", "🕷️", "🕸️"],
      "nature" => ["💐", "🌸", "💮", "🏵️", "🌹", "🥀", "🌺", "🌻", "🌼", "🌷", "🌱", "🌲", "🌳", "🌴", "🌵", "🌾", "🌿", "☘️", "🍀", "🍁", "🍂", "🍃", "🍄", "🌰", "🦀", "🦞", "🦐", "🦑", "🐙", "🦪", "🐚", "🪨", "🌍", "🌎", "🌏", "🌐", "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"],
      "food" => ["🍏", "🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑", "🥦", "🥬", "🥒", "🌶️", "🌽", "🥕", "🧄", "🧅", "🥔", "🍠", "🥐", "🥯", "🍞", "🥖", "🥨", "🧀", "🥚", "🍳", "🧈", "🥞", "🧇", "🥓", "🥩", "🍗", "🍖"],
      "drinks" => ["☕", "🍵", "🧃", "🥤", "🧋", "🍶", "🍺", "🍻", "🥂", "🍷", "🥃", "🍸", "🍹", "🧉", "🍾", "🧊", "🥄", "🍴", "🍽️", "🥣", "🥡", "🥢", "🧂"],
      "sports" => ["⚽", "🏀", "🏈", "⚾", "🥎", "🎾", "🏐", "🏉", "🥏", "🎱", "🪀", "🏓", "🏸", "🏒", "🏑", "🥍", "🏏", "🪃", "🥅", "⛳", "🪁", "🏹", "🎣", "🤿", "🥊", "🥋", "🎽", "🛹", "🛼", "🛷", "⛸️", "🥌", "🎿", "⛷️", "🏂", "🪂", "🏋️", "🤼", "🤸", "🤺", "⛹️", "🤾", "🏌️", "🏇"],
      "travel" => ["🚗", "🚕", "🚙", "🚌", "🚎", "🏎️", "🚓", "🚑", "🚒", "🚐", "🛻", "🚚", "🚛", "🚜", "🦯", "🦽", "🦼", "🛴", "🚲", "🛵", "🏍️", "🛺", "🚨", "🚔", "🚍", "🚘", "🚖", "🚡", "🚠", "🚟", "🚃", "🚋", "🚞", "🚝", "🚄", "🚅", "🚈", "🚂", "🚆", "🚇", "🚊", "🚉", "✈️", "🛫"],
      "objects" => ["⌚", "📱", "📲", "💻", "⌨️", "🖥️", "🖨️", "🖱️", "🖲️", "🕹️", "🗜️", "💾", "💿", "📀", "📼", "📷", "📸", "📹", "🎥", "📽️", "🎞️", "📞", "☎️", "📟", "📠", "📺", "📻", "🎙️", "🎚️", "🎛️", "🧭", "⏱️", "⏲️", "⏰", "🕰️", "⌛", "⏳", "📡", "🔋", "🔌", "💡", "🔦", "🕯️", "🪔", "🧯"],
      "symbols" => ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟", "☮️", "✝️", "☪️", "🕉️", "☸️", "✡️", "🔯", "🕎", "☯️", "☦️", "🛐", "⛎", "♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓", "🆔"],
      "flags" => ["🏁", "🚩", "🎌", "🏴", "🏳️", "🏳️‍🌈", "🏳️‍⚧️", "🏴‍☠️", "🇦🇨", "🇦🇩", "🇦🇪", "🇦🇫", "🇦🇬", "🇦🇮", "🇦🇱", "🇦🇲", "🇦🇴", "🇦🇶", "🇦🇷", "🇦🇸", "🇦🇹", "🇦🇺", "🇦🇼", "🇦🇽", "🇦🇿", "🇧🇦", "🇧🇧", "🇧🇩", "🇧🇪", "🇧🇫", "🇧🇬", "🇧🇭", "🇧🇮", "🇧🇯", "🇧🇱", "🇧🇲", "🇧🇳", "🇧🇴", "🇧🇶", "🇧🇷", "🇧🇸", "🇧🇹", "🇧🇻", "🇧🇼"]
    }
  end

  defp get_emoji_category(category) do
    get_all_emojis()[category] || []
  end

  defp search_emojis(search_term) do
    search_term = String.downcase(search_term)

    all_emojis = get_all_emojis()

    # Define searchable keywords for each category
    keywords = %{
      "smileys" => ["smile", "happy", "laugh", "grin", "joy", "face"],
      "emotions" => ["sad", "cry", "angry", "sick", "tired", "emotion", "feel"],
      "people" => ["person", "people", "man", "woman", "child", "baby", "old"],
      "gestures" => ["hand", "finger", "thumb", "point", "wave", "clap", "pray"],
      "animals" => ["animal", "dog", "cat", "bird", "fish", "pet", "wild"],
      "nature" => ["flower", "plant", "tree", "leaf", "nature", "earth", "moon"],
      "food" => ["food", "fruit", "vegetable", "meal", "eat"],
      "drinks" => ["drink", "coffee", "tea", "beer", "wine", "cup"],
      "sports" => ["sport", "ball", "game", "play", "exercise"],
      "travel" => ["car", "travel", "vehicle", "transport", "train", "plane"],
      "objects" => ["object", "phone", "computer", "clock", "camera", "tool"],
      "symbols" => ["heart", "love", "symbol", "sign", "star"],
      "flags" => ["flag", "country", "nation"]
    }

    # Find matching categories
    matching_categories =
      Enum.filter(keywords, fn {_category, words} ->
        Enum.any?(words, fn word -> String.contains?(word, search_term) end)
      end)
      |> Enum.map(fn {category, _} -> category end)

    # Get emojis from matching categories
    matching_categories
    |> Enum.flat_map(fn category -> all_emojis[category] || [] end)
    |> Enum.take(64) # Limit results
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container max-w-2xl py-6 mx-auto space-y-4">
      <.ui_card>
        <.ui_card_header class="border-b">
          <.ui_card_title class="text-2xl">Home</.ui_card_title>
        </.ui_card_header>

        <.ui_card_content class="pt-6">
          <.post_composer
            current_user={@current_user}
            body={@post_body}
            char_count={@char_count}
            uploaded_files={@uploaded_files}
            uploads={@uploads}
            submit_event="post_post"
            update_event="update_post"
            placeholder="What's happening?"
          />
        </.ui_card_content>
      </.ui_card>

      <!-- Timeline -->
      <div id="posts" phx-update="stream" class="space-y-4">
        <.post_card
          :for={{dom_id, post} <- @streams.posts}
          dom_id={dom_id}
          post={post}
          current_user={@current_user}
        />
      </div>

      <!-- Giphy Modal -->
      <div
        :if={@giphy_modal_open}
        class="fixed inset-0 z-50 flex items-start justify-center p-4 bg-black/50"
        phx-click="close_giphy"
      >
        <div
          class="w-full max-w-4xl mt-20 overflow-hidden rounded-lg shadow-lg bg-background"
          phx-click="stop_propagation"
        >
          <div class="flex items-center justify-between p-4 border-b border-border">
            <h2 class="text-lg font-semibold">Choose a GIF</h2>
            <button
              phx-click="close_giphy"
              class="p-2 transition-colors rounded-full hover:bg-muted"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>

          <div class="p-4">
            <input
              type="text"
              value={@giphy_search}
              phx-keyup="search_giphy"
              phx-debounce="300"
              placeholder="Search for GIFs..."
              class="w-full px-4 py-2 mb-4 transition-colors border rounded-md bg-background border-border focus:outline-none focus:ring-2 focus:ring-primary"
            />

            <div class="grid grid-cols-3 gap-2 overflow-y-auto max-h-96">
              <%= for gif <- @giphy_results do %>
                <button
                  type="button"
                  phx-click="select_gif"
                  phx-value-url={gif["images"]["fixed_height"]["url"]}
                  class="relative overflow-hidden transition-transform rounded-lg aspect-square hover:scale-105"
                >
                  <img
                    src={gif["images"]["fixed_height"]["url"]}
                    alt={gif["title"]}
                    class="object-cover w-full h-full"
                  />
                </button>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <!-- Reply Modal -->
      <div
        :if={@reply_modal_open}
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
        phx-click="close_reply_modal"
      >
        <div
          class="w-full max-w-xl overflow-hidden rounded-lg shadow-lg bg-background"
          phx-click="stop_propagation"
        >
          <div class="flex items-center justify-between p-4 border-b border-border">
            <h2 class="text-lg font-semibold">Reply to @<%= @reply_to_post && @reply_to_post.user.username %></h2>
            <button
              phx-click="close_reply_modal"
              class="p-2 transition-colors rounded-full hover:bg-muted"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>

          <div class="p-4">
            <.post_composer
              current_user={@current_user}
              body={@reply_content}
              char_count={@reply_char_count}
              uploaded_files={[]}
              uploads={@uploads}
              submit_event="post_reply"
              update_event="update_reply"
              placeholder="Post your reply"
              reply_to={@reply_to_post}
              show_cancel={true}
              cancel_event="close_reply_modal"
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end
end
