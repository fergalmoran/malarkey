defmodule MalarkeyWeb.UserLoginLive do
  use MalarkeyWeb, :live_view

  import MalarkeyWeb.Components.UI

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center px-4 py-12">
      <.ui_card class="w-full max-w-md">
        <.ui_card_header>
          <.ui_card_title class="text-2xl text-center">Welcome back</.ui_card_title>
          <.ui_card_description class="text-center">
            Sign in to your account to continue
          </.ui_card_description>
        </.ui_card_header>

        <.ui_card_content>
          <.form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore" class="space-y-4">
            <.ui_input field={@form[:email]} type="email" label="Email" required />
            <.ui_input field={@form[:password]} type="password" label="Password" required />

            <div class="flex items-center justify-between">
              <.ui_input field={@form[:remember_me]} type="checkbox" label="Remember me" />
              <.link href={~p"/users/reset_password"} class="text-sm font-medium text-primary hover:underline">
                Forgot password?
              </.link>
            </div>

            <.ui_button type="submit" class="w-full" phx-disable-with="Signing in...">
              Sign in
            </.ui_button>
          </.form>

          <div class="mt-6">
            <.ui_separator class="my-4" />
            <p class="text-center text-sm text-muted-foreground mb-4">Or continue with</p>

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

          <p class="mt-4 text-center text-sm text-muted-foreground">
            Don't have an account?
            <.link navigate={~p"/users/register"} class="font-medium text-primary hover:underline">
              Sign up
            </.link>
          </p>
        </.ui_card_content>
      </.ui_card>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
