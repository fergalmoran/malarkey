defmodule MalarkeyWeb.Router do
  use MalarkeyWeb, :router

  import MalarkeyWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MalarkeyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Routes for unauthenticated users
  scope "/", MalarkeyWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{MalarkeyWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  # OAuth routes
  scope "/auth", MalarkeyWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # Routes for authenticated users
  scope "/", MalarkeyWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{MalarkeyWeb.UserAuth, :ensure_authenticated}] do
      live "/", TimelineLive.Index, :index
      live "/compose", TimelineLive.Index, :compose
      live "/notifications", NotificationLive.Index, :index
      live "/explore", ExploreLive.Index, :index

      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
      live "/settings/profile", ProfileSettingsLive, :edit

      live "/posts/:id", PostLive.Show, :show

      live "/:username", ProfileLive.Index, :index
      live "/:username/with_replies", ProfileLive.Index, :with_replies
      live "/:username/media", ProfileLive.Index, :media
      live "/:username/likes", ProfileLive.Index, :likes
      live "/:username/followers", ProfileLive.Followers, :index
      live "/:username/following", ProfileLive.Following, :index

      live "/:username/status/:id", PostLive.Show, :show
    end

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationInstructionsController, :new
    post "/users/confirm", UserConfirmationInstructionsController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end

  # Public routes that work for both authenticated and non-authenticated users
  scope "/", MalarkeyWeb do
    pipe_through :browser

    live_session :public,
      on_mount: [{MalarkeyWeb.UserAuth, :mount_current_user}] do
      live "/about", PageLive.About, :index
      live "/explore/public", ExploreLive.Public, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", MalarkeyWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:malarkey, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MalarkeyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
