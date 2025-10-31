defmodule MalarkeyWeb.UserRegistrationLive do
  use MalarkeyWeb, :live_view

  import MalarkeyWeb.Components.UI

  alias Malarkey.Accounts
  alias Malarkey.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center min-h-screen px-4 py-12">
      <.ui_card class="w-full max-w-md">
        <.ui_card_header>
          <.ui_card_title class="text-2xl text-center">Create an account</.ui_card_title>
          <.ui_card_description class="text-center">
            Enter your details below to create your account
          </.ui_card_description>
        </.ui_card_header>

        <.ui_card_content>
          <.form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            phx-trigger-action={@trigger_submit}
            action={~p"/users/log_in?_action=registered"}
            method="post"
            class="space-y-4"
          >
            <.ui_alert :if={@check_errors} variant="destructive">
              Oops, something went wrong! Please check the errors below.
            </.ui_alert>

            <.ui_input field={@form[:username]} type="text" label="Username" required />
            <.ui_input field={@form[:email]} type="email" label="Email" required />
            <.ui_input field={@form[:password]} type="password" label="Password" required />

            <.ui_button type="submit" class="w-full" phx-disable-with="Creating account...">
              Create account
            </.ui_button>
          </.form>

          <div class="mt-6">
            <.ui_separator class="my-4" />
            <p class="mb-4 text-sm text-center text-muted-foreground">Or continue with</p>

            <div class="grid grid-cols-3 gap-3">
              <.link href={~p"/auth/google"}>
                <.ui_button variant="outline" class="w-full">
                  Google
                </.ui_button>
              </.link>
              <.link href={~p"/auth/github"}>
                <.ui_button variant="outline" class="w-full">
                  GitHub
                </.ui_button>
              </.link>
              <.link href={~p"/auth/twitter"}>
                <.ui_button variant="outline" class="w-full">
                  Twitter
                </.ui_button>
              </.link>
            </div>
          </div>

          <p class="mt-4 text-sm text-center text-muted-foreground">
            Already have an account?
            <.link navigate={~p"/users/log_in"} class="font-medium text-primary hover:underline">
              Sign in
            </.link>
          </p>
        </.ui_card_content>
      </.ui_card>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
