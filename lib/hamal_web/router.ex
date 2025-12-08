defmodule HamalWeb.Router do
  use HamalWeb, :router

  import HamalWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HamalWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :admin_section do
    plug HamalWeb.AdminAuth
    plug :put_layout, html: {HamalWeb.Layouts, :admin}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # scope "/", HamalWeb do
  #   pipe_through [:browser]

  #   get "/", HomeController, :index
  # end

  # Other scopes may use custom stacks.
  # scope "/api", HamalWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:hamal, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HamalWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Admin routes

  scope "/admin", HamalWeb.Admin, as: :admin do
    pipe_through [:browser, :admin_section]

    get "/", HomeController, :index
    resources "/users", UserController
    resources "/rooms", RoomController

    live_session :admin,
      layout: {HamalWeb.Layouts, :admin},
      on_mount: {HamalWeb.ActiveNavLink, :active_item} do
      live "/guests", GuestLive.Index, :index
      live "/guests/new", GuestLive.Index, :new
      live "/guests/:id", GuestLive.Index, :edit
      live "/reservations", ReservationLive.Index, :index
      live "/reservations/new", ReservationLive.Index, :new
      live "/reservations/:id/edit", ReservationLive.Index, :edit
      live "/reservations/:id/show", ReservationLive.Index, :show
      live "/stays", StaysLive.Index, :index
      live "/check_in/:reservation_id", CheckInLive
    end
  end

  ## Authentication routes - User routes

  scope "/", HamalWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{HamalWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/login", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/login", UserSessionController, :create
  end

  scope "/", HamalWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/", HomeController, :index

    live_session :require_authenticated_user,
      on_mount: [{HamalWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", HamalWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{HamalWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
