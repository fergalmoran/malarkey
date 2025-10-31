defmodule MalarkeyWeb.UserForgotPasswordLive do
  use MalarkeyWeb, :live_view

  import MalarkeyWeb.Components.UI

  alias Malarkey.Accounts

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center px-4 py-12">
      <.ui_card class="w-full max-w-md">
        <.ui_card_header>
          <.ui_card_title class="text-2xl text-center">Forgot password?</.ui_card_title>
          <.ui_card_description class="text-center">
            We'll send a password reset link to your inbox
          </.ui_card_description>
        </.ui_card_header>

        <.ui_card_content>
          <.form for={@form} id="reset_password_form" phx-submit="send_email" class="space-y-4">
            <.ui_input field={@form[:email]} type="email" label="Email" placeholder="your@email.com" required />

            <.ui_button type="submit" class="w-full" phx-disable-with="Sending...">
              Send reset instructions
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

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
