defmodule MalarkeyWeb.UserLiveAuth do
  require Logger
  import Phoenix.Component
  alias Malarkey.Accounts
  alias Accounts.User

  @spec on_mount(:default, any, any, map) ::
          {:cont, %{:assigns => atom | map, optional(any) => any}}
  def on_mount(:default, _params, session, socket) do
    Logger.info("Mounting user live auth")
    Logger.debug(session)

    socket = assign_new(socket, :current_user, fn -> get_current_user(session) end)
    {:cont, socket}
  end

  defp get_current_user(session) do
    with user_token when not is_nil(user_token) <- session["user_token"],
         %User{} = user <- Accounts.get_user_by_session_token(session["user_token"]) do
      user
    end
  end
end
