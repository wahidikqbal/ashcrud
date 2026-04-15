defmodule AshcrudWeb.Router do
  use AshcrudWeb, :router

  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AshcrudWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/", AshcrudWeb do
    pipe_through :browser

    ash_authentication_live_session :authenticated_routes do
      # in each liveview, add one of the following at the top of the module:
      #
      # If an authenticated user must be present:
      # on_mount {AshcrudWeb.LiveUserAuth, :live_user_required}
      #
      # If an authenticated user *may* be present:
      # on_mount {AshcrudWeb.LiveUserAuth, :live_user_optional}
      #
      # If an authenticated user must *not* be present:
      # on_mount {AshcrudWeb.LiveUserAuth, :live_no_user}


      # LiveView Category Routes
      live "/categories", CategoryLive.Index, :index
      live "/categories/new", CategoryLive.Form, :new
      live "/categories/:id/edit", CategoryLive.Form, :edit
      live "/categories/:id", CategoryLive.Show, :show
      live "/categories/:id/show/edit", CategoryLive.Show, :edit

      # LiveView Material Routes
      live "/materials", MaterialLive.Index, :index
      live "/materials/new", MaterialLive.Form, :new
      live "/materials/:id/edit", MaterialLive.Form, :edit
      live "/materials/:id", MaterialLive.Show, :show
      live "/materials/:id/show/edit", MaterialLive.Show, :edit

      # LiveView Item Routes
      live "/items", ItemLive.Index, :index
      live "/items/new", ItemLive.Form, :new
      live "/items/:id/edit", ItemLive.Form, :edit
      live "/items/:id", ItemLive.Show, :show
      live "/items/:id/show/edit", ItemLive.Show, :edit

      # LiveView Supplier Routes
      live "/suppliers", SupplierLive.Index, :index
      live "/suppliers/new", SupplierLive.Form, :new
      live "/suppliers/:id/edit", SupplierLive.Form, :edit
      live "/suppliers/:id", SupplierLive.Show, :show
      live "/suppliers/:id/show/edit", SupplierLive.Show, :edit

    end
  end

  scope "/", AshcrudWeb do
    pipe_through :browser

    get "/", PageController, :home
    
    live "/posts", PostLive.Index, :index
    live "/posts/new", PostLive.Form, :new
    live "/posts/:id/edit", PostLive.Form, :edit
    live "/posts/:id", PostLive.Show, :show
    live "/posts/:id/show/edit", PostLive.Show, :edit
    auth_routes AuthController, Ashcrud.Accounts.User, path: "/auth"
    sign_out_route AuthController

    # Remove these if you'd like to use your own authentication views
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [{AshcrudWeb.LiveUserAuth, :live_no_user}],
                  overrides: [
                    AshcrudWeb.AuthOverrides,
                    Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI
                  ]

    # Remove this if you do not want to use the reset password feature
    reset_route auth_routes_prefix: "/auth",
                overrides: [
                  AshcrudWeb.AuthOverrides,
                  Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI
                ]

    # Remove this if you do not use the confirmation strategy
    confirm_route Ashcrud.Accounts.User, :confirm_new_user,
      auth_routes_prefix: "/auth",
      overrides: [AshcrudWeb.AuthOverrides, Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI]

    # Remove this if you do not use the magic link strategy.
    magic_sign_in_route(Ashcrud.Accounts.User, :magic_link,
      auth_routes_prefix: "/auth",
      overrides: [AshcrudWeb.AuthOverrides, Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI]
    )
  end

  # Other scopes may use custom stacks.
  # scope "/api", AshcrudWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ashcrud, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AshcrudWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  if Application.compile_env(:ashcrud, :dev_routes) do
    import AshAdmin.Router

    scope "/admin" do
      pipe_through :browser

      ash_admin "/"
    end
  end
end
