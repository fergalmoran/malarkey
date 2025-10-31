defmodule MalarkeyWeb.UserConfirmationInstructionsController do
  use MalarkeyWeb, :controller

  alias Malarkey.Accounts

  def new(conn, _params) do
    render(conn, :new, page_title: "Resend confirmation instructions")
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: ~p"/")
  end
end
