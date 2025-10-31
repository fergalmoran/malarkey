defmodule MalarkeyWeb.UserSettingsLive do
  use MalarkeyWeb, :live_view

  import MalarkeyWeb.Components.UI

  alias Malarkey.Accounts

  def render(assigns) do
    ~H"""
    <div class="container max-w-4xl py-8 px-4">
      <div class="mb-8">
        <h1 class="text-3xl font-bold">Account Settings</h1>
        <p class="text-muted-foreground mt-2">Manage your account profile and password settings</p>
      </div>

      <div class="space-y-6">
        <.ui_card>
          <.ui_card_header>
            <.ui_card_title>Appearance</.ui_card_title>
            <.ui_card_description>Customize the appearance of the app</.ui_card_description>
          </.ui_card_header>
          <.ui_card_content>
            <div class="space-y-4">
              <div>
                <label class="text-sm font-medium">Theme</label>
                <p class="text-sm text-muted-foreground mb-3">
                  Select your preferred color scheme
                </p>
                <div class="grid grid-cols-3 gap-3">
                  <button
                    phx-hook="ThemeSelector"
                    data-theme="light"
                    id="theme-light"
                    class="flex flex-col items-center gap-2 p-4 rounded-lg border-2 border-input hover:border-primary transition-colors bg-background"
                  >
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
                      />
                    </svg>
                    <span class="text-sm font-medium">Light</span>
                  </button>

                  <button
                    phx-hook="ThemeSelector"
                    data-theme="dark"
                    id="theme-dark"
                    class="flex flex-col items-center gap-2 p-4 rounded-lg border-2 border-input hover:border-primary transition-colors bg-background"
                  >
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
                      />
                    </svg>
                    <span class="text-sm font-medium">Dark</span>
                  </button>

                  <button
                    phx-hook="ThemeSelector"
                    data-theme="system"
                    id="theme-system"
                    class="flex flex-col items-center gap-2 p-4 rounded-lg border-2 border-input hover:border-primary transition-colors bg-background"
                  >
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                      />
                    </svg>
                    <span class="text-sm font-medium">System</span>
                  </button>
                </div>
              </div>
            </div>
          </.ui_card_content>
        </.ui_card>

        <.ui_card>
          <.ui_card_header>
            <.ui_card_title>Profile Information</.ui_card_title>
            <.ui_card_description>Update your public profile information</.ui_card_description>
          </.ui_card_header>
          <.ui_card_content>
            <.form
              for={@profile_form}
              id="profile_form"
              phx-submit="update_profile"
              phx-change="validate_profile"
              class="space-y-4"
            >
              <.ui_input field={@profile_form[:display_name]} type="text" label="Display name" />
              <.ui_input field={@profile_form[:username]} type="text" label="Username" required />
              <.ui_input field={@profile_form[:bio]} type="textarea" label="Bio" />
              <.ui_input field={@profile_form[:location]} type="text" label="Location" />
              <.ui_input field={@profile_form[:website]} type="url" label="Website" />
              <.ui_button type="submit" phx-disable-with="Saving...">Save Profile</.ui_button>
            </.form>
          </.ui_card_content>
        </.ui_card>

        <.ui_card>
          <.ui_card_header>
            <.ui_card_title>Email Address</.ui_card_title>
            <.ui_card_description>Change your email address</.ui_card_description>
          </.ui_card_header>
          <.ui_card_content>
            <.form
              for={@email_form}
              id="email_form"
              phx-submit="update_email"
              phx-change="validate_email"
              class="space-y-4"
            >
              <.ui_input field={@email_form[:email]} type="email" label="Email" required />
              <.ui_input
                field={@email_form[:current_password]}
                name="current_password"
                id="current_password_for_email"
                type="password"
                label="Current password"
                value={@email_form_current_password}
                required
              />
              <.ui_button type="submit" phx-disable-with="Changing...">Change Email</.ui_button>
            </.form>
          </.ui_card_content>
        </.ui_card>

        <.ui_card>
          <.ui_card_header>
            <.ui_card_title>Password</.ui_card_title>
            <.ui_card_description>Update your password</.ui_card_description>
          </.ui_card_header>
          <.ui_card_content>
            <.form
              for={@password_form}
              id="password_form"
              action={~p"/users/log_in?_action=password_updated"}
              method="post"
              phx-change="validate_password"
              phx-submit="update_password"
              phx-trigger-action={@trigger_submit}
              class="space-y-4"
            >
              <input
                name={@password_form[:email].name}
                type="hidden"
                id="hidden_user_email"
                value={@current_email}
              />
              <.ui_input field={@password_form[:password]} type="password" label="New password" required />
              <.ui_input
                field={@password_form[:password_confirmation]}
                type="password"
                label="Confirm new password"
              />
              <.ui_input
                field={@password_form[:current_password]}
                name="current_password"
                type="password"
                label="Current password"
                id="current_password_for_password"
                value={@current_password}
                required
              />
              <.ui_button type="submit" phx-disable-with="Changing...">Change Password</.ui_button>
            </.form>
          </.ui_card_content>
        </.ui_card>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    profile_changeset = Accounts.change_user_profile(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    profile_form =
      socket.assigns.current_user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", %{"user" => user_params}, socket) do
    case Accounts.update_user_profile(socket.assigns.current_user, user_params) do
      {:ok, _user} ->
        info = "Profile updated successfully."

        {:noreply,
         socket
         |> put_flash(:info, info)
         |> assign(:profile_form, to_form(Accounts.change_user_profile(socket.assigns.current_user)))}

      {:error, changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(changeset))}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
