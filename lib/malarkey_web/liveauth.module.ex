defmodule MalarkeyWeb.UserLiveAuth do
  import Phoenix.Component
  alias Malarkey.Accounts
  def on_mount(:default, _params, session, socket) do
    socket =
      assign_new(
        socket,
        :current_user,
        fn -> Accounts.get_user_by_session_token(session["user_token"]) end
      )

    if socket.assigns.current_user == nil do
      {:cont, socket}
    else
      {:cont, socket}
    end
  end
end
