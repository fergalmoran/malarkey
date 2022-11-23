defmodule MalarkeyWeb.UserLiveAuth do
  require Logger
  import Phoenix.Component
  alias Malarkey.Accounts

  @spec on_mount(:default, any, any, map) ::
          {:cont, %{:assigns => atom | map, optional(any) => any}}
  def on_mount(:default, _params, session, socket) do
    Logger.info("Mounting user live auth")
    Logger.debug(session)

    if session["user_token"] == nil do
      Logger.info("No user_token found")

      socket =
        assign_new(
          socket,
          :current_user,
          fn -> nil end
        )

      {:cont, socket}
    else
      Logger.info("Found user_token")

      socket =
        assign_new(
          socket,
          :current_user,
          fn -> Accounts.get_user_by_session_token(session["user_token"]) end
        )

      {:cont, socket}
    end
  end
end
