defmodule MalarkeyWeb.UserResetPasswordLive do
  use MalarkeyWeb, :live_view

  import MalarkeyWeb.Components.UI

  alias Malarkey.Accounts

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center px-4 py-12">
      <.ui_card class="w-full max-w-md">
        <.ui_card_header>
          <.ui_card_title class="text-2xl text-center">Reset password</.ui_card_title>
          <.ui_card_description class="text-center">
            Enter your new password below
          </.ui_card_description>
        </.ui_card_header>

        <.ui_card_content>
          <.form
            for={@form}
            id="reset_password_form"
            phx-submit="reset_password"
            phx-change="validate"
            class="space-y-4"
          >
            <.ui_alert :if={@form.errors != []} variant="destructive">
              Oops, something went wrong! Please check the errors below.
            </.ui_alert>

            <.ui_input field={@form[:password]} type="password" label="New password" required />
            <.ui_input
              field={@form[:password_confirmation]}
              type="password"
              label="Confirm new password"
              required
            />

            <.ui_button type="submit" class="w-full" phx-disable-with="Resetting...">
              Reset password
            </.ui_button>
          </.form>

          <p class="mt-4 text-center text-sm text-muted-foreground">
            <.link href={~p"/users/register"} class="font-medium text-primary hover:underline">Register</.link>
            {" · "}
            <.link href={~p"/users/log_in"} class="font-medium text-primary hover:underline">Log in</.link>
          </p>
        </.ui_card_content>
      </.ui_card>
    </div>
    """
  end

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{user: user} ->
          Accounts.change_user_password(user)

        _ ->
          %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "user"))
  end
end
