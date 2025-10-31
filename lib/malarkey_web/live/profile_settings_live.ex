defmodule MalarkeyWeb.ProfileSettingsLive do
  use MalarkeyWeb, :live_view

  alias Malarkey.{Accounts, Media}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    changeset = Accounts.User.profile_changeset(user, %{})

    {:ok,
     socket
     |> assign(:page_title, "Edit Profile")
     |> assign(:changeset, changeset)
     |> assign(:avatar_preview, user.avatar_url)
     |> assign(:header_preview, user.header_url)
     |> allow_upload(:avatar,
       accept: ~w(.jpg .jpeg .png .gif),
       max_entries: 1,
       max_file_size: 5_000_000
     )
     |> allow_upload(:header,
       accept: ~w(.jpg .jpeg .png .gif),
       max_entries: 1,
       max_file_size: 5_000_000
     )}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.User.profile_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("cancel_avatar", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl true
  def handle_event("cancel_header", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :header, ref)}
  end

  @impl true
  def handle_event("remove_avatar", _params, socket) do
    case Accounts.update_user_profile(socket.assigns.current_user, %{avatar_url: nil}) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> assign(:avatar_preview, nil)
         |> put_flash(:info, "Avatar removed successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to remove avatar")}
    end
  end

  @impl true
  def handle_event("remove_header", _params, socket) do
    case Accounts.update_user_profile(socket.assigns.current_user, %{header_url: nil}) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> assign(:header_preview, nil)
         |> put_flash(:info, "Header image removed successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to remove header image")}
    end
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    # Handle avatar upload
    avatar_url =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        case Media.upload_file(path, entry.client_type, socket.assigns.current_user.id) do
          {:ok, url} -> {:ok, url}
          {:error, _} -> {:postpone, :error}
        end
      end)
      |> List.first()

    # Handle header upload
    header_url =
      consume_uploaded_entries(socket, :header, fn %{path: path}, entry ->
        case Media.upload_file(path, entry.client_type, socket.assigns.current_user.id) do
          {:ok, url} -> {:ok, url}
          {:error, _} -> {:postpone, :error}
        end
      end)
      |> List.first()

    # Merge uploaded URLs with form params
    user_params =
      user_params
      |> maybe_put_avatar(avatar_url)
      |> maybe_put_header(header_url)

    case Accounts.update_user_profile(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> assign(:avatar_preview, user.avatar_url)
         |> assign(:header_preview, user.header_url)
         |> put_flash(:info, "Profile updated successfully")
         |> push_navigate(to: ~p"/#{user.username}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp maybe_put_avatar(params, nil), do: params
  defp maybe_put_avatar(params, url), do: Map.put(params, "avatar_url", url)

  defp maybe_put_header(params, nil), do: params
  defp maybe_put_header(params, url), do: Map.put(params, "header_url", url)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <div class="mb-6">
        <.link navigate={~p"/#{@current_user.username}"} class="text-blue-500 hover:underline">
          ← Back to profile
        </.link>
      </div>

      <div class="p-6 bg-white rounded-lg shadow dark:bg-gray-800">
        <h1 class="mb-6 text-2xl font-bold">Edit Profile</h1>

        <.form
          :let={f}
          for={@changeset}
          id="profile-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-8"
        >
          <!-- Avatar Image -->
          <div class="pb-8 border-b border-gray-200 dark:border-gray-700">
            <label class="block mb-4 text-sm font-medium">Profile Picture</label>
            <div class="flex items-center gap-4">
              <div class="relative">
                <%= if @avatar_preview do %>
                  <img
                    src={@avatar_preview}
                    alt="Avatar"
                    class="object-cover w-32 h-32 border-4 border-white rounded-full dark:border-gray-800"
                  />
                <% else %>
                  <div class="flex items-center justify-center w-32 h-32 text-4xl font-bold text-gray-600 bg-gray-300 border-4 border-white rounded-full dark:bg-gray-600 dark:text-gray-300 dark:border-gray-800">
                    <%= String.first(@current_user.username) |> String.upcase() %>
                  </div>
                <% end %>
              </div>
              <div class="flex gap-2">
                <label
                  for={@uploads.avatar.ref}
                  class="px-4 py-2 text-sm font-semibold text-white transition-colors bg-blue-500 rounded-full cursor-pointer hover:bg-blue-600"
                >
                  <svg class="inline w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"
                    />
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M15 13a3 3 0 11-6 0 3 3 0 016 0z"
                    />
                  </svg>
                  Upload Photo
                </label>
                <%= if @avatar_preview do %>
                  <button
                    type="button"
                    phx-click="remove_avatar"
                    class="px-4 py-2 text-sm font-semibold text-white transition-colors bg-red-500 rounded-full hover:bg-red-600"
                  >
                    Remove
                  </button>
                <% end %>
              </div>
            </div>
            <.live_file_input upload={@uploads.avatar} class="hidden" />

            <%= for entry <- @uploads.avatar.entries do %>
              <div class="flex items-center justify-between p-2 mt-2 bg-gray-100 rounded dark:bg-gray-700">
                <span class="text-sm"><%= entry.client_name %></span>
                <button
                  type="button"
                  phx-click="cancel_avatar"
                  phx-value-ref={entry.ref}
                  class="text-red-500 hover:text-red-700"
                >
                  ✕
                </button>
              </div>
            <% end %>
          </div>

          <!-- Header Image -->
          <div class="pb-8 border-b border-gray-200 dark:border-gray-700">
            <label class="block mb-4 text-sm font-medium">Header Image</label>
            <div class="relative">
              <div class="h-48 overflow-hidden bg-gradient-to-r from-blue-400 to-purple-500 rounded-lg">
                <%= if @header_preview do %>
                  <img src={@header_preview} alt="Header" class="object-cover w-full h-full" />
                <% end %>
              </div>
              <div class="absolute flex gap-2 top-2 right-2">
                <label
                  for={@uploads.header.ref}
                  class="px-3 py-2 text-sm font-semibold text-white transition-colors bg-black rounded-full cursor-pointer bg-opacity-60 hover:bg-opacity-80"
                >
                  <svg class="inline w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"
                    />
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M15 13a3 3 0 11-6 0 3 3 0 016 0z"
                    />
                  </svg>
                  Change
                </label>
                <%= if @header_preview do %>
                  <button
                    type="button"
                    phx-click="remove_header"
                    class="px-3 py-2 text-sm font-semibold text-white transition-colors bg-red-600 rounded-full bg-opacity-60 hover:bg-opacity-80"
                  >
                    Remove
                  </button>
                <% end %>
              </div>
            </div>
            <.live_file_input upload={@uploads.header} class="hidden" />

            <%= for entry <- @uploads.header.entries do %>
              <div class="flex items-center justify-between p-2 mt-2 bg-gray-100 rounded dark:bg-gray-700">
                <span class="text-sm"><%= entry.client_name %></span>
                <button
                  type="button"
                  phx-click="cancel_header"
                  phx-value-ref={entry.ref}
                  class="text-red-500 hover:text-red-700"
                >
                  ✕
                </button>
              </div>
            <% end %>
          </div>

          <!-- Display Name -->
          <div>
            <.input
              field={f[:display_name]}
              type="text"
              label="Display Name"
              placeholder="Your display name"
            />
          </div>

          <!-- Bio -->
          <div>
            <.input
              field={f[:bio]}
              type="textarea"
              label="Bio"
              placeholder="Tell us about yourself"
              rows="3"
            />
            <p class="mt-1 text-sm text-gray-500">
              <%= String.length(Phoenix.HTML.Form.input_value(f, :bio) || "") %>/160
            </p>
          </div>

          <!-- Location -->
          <div>
            <.input field={f[:location]} type="text" label="Location" placeholder="Where are you?" />
          </div>

          <!-- Website -->
          <div>
            <.input
              field={f[:website]}
              type="text"
              label="Website"
              placeholder="https://example.com"
            />
          </div>

          <!-- Actions -->
          <div class="flex gap-3">
            <button
              type="submit"
              class="flex-1 px-6 py-2 font-semibold text-white transition-colors bg-blue-500 rounded-full hover:bg-blue-600"
              phx-disable-with="Saving..."
            >
              Save Changes
            </button>
            <.link
              navigate={~p"/#{@current_user.username}"}
              class="flex items-center justify-center flex-1 px-6 py-2 font-semibold text-gray-700 transition-colors border border-gray-300 rounded-full hover:bg-gray-100 dark:text-gray-300 dark:border-gray-600 dark:hover:bg-gray-800"
            >
              Cancel
            </.link>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
