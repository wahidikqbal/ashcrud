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

   # Main scope with authentication
   scope "/", AshcrudWeb do
     pipe_through :browser

     # All authenticated LiveView routes in ONE live session
     ash_authentication_live_session :authenticated_routes,
       on_mount: [
         {AshcrudWeb.LiveUserAuth, :live_user_required}
       ] do

       # Category routes
       live "/categories", CategoryLive.Index, :index
       live "/categories/new", CategoryLive.Form, :new
       live "/categories/:id/edit", CategoryLive.Form, :edit
       live "/categories/:id", CategoryLive.Show, :show
       live "/categories/:id/show/edit", CategoryLive.Show, :edit

       # Item routes
       live "/items", ItemLive.Index, :index
       live "/items/new", ItemLive.Form, :new
       live "/items/:id/edit", ItemLive.Form, :edit
       live "/items/:id", ItemLive.Show, :show
       live "/items/:id/show/edit", ItemLive.Show, :edit

       # Supplier routes
       live "/suppliers", SupplierLive.Index, :index
       live "/suppliers/new", SupplierLive.Form, :new
       live "/suppliers/:id/edit", SupplierLive.Form, :edit
       live "/suppliers/:id", SupplierLive.Show, :show
       live "/suppliers/:id/show/edit", SupplierLive.Show, :edit

       # Post routes
       live "/posts", PostLive.Index, :index
       live "/posts/new", PostLive.Form, :new
       live "/posts/:id/edit", PostLive.Form, :edit
       live "/posts/:id", PostLive.Show, :show
       live "/posts/:id/show/edit", PostLive.Show, :edit
     end

     # Admin-only routes (auth + admin check)
     ash_authentication_live_session :admin_routes,
       on_mount: [
         {AshcrudWeb.LiveUserAuth, :live_user_required},
         {AshcrudWeb.RequireAdmin, :default}
       ] do
       # Material routes - admin only
       live "/materials", MaterialLive.Index, :index
       live "/materials/new", MaterialLive.Form, :new
       live "/materials/:id/edit", MaterialLive.Form, :edit
       live "/materials/:id", MaterialLive.Show, :show
       live "/materials/:id/show/edit", MaterialLive.Show, :edit
     end
   end

  # Public routes (non-LiveView, authentication flows, etc.)
  scope "/", AshcrudWeb do
    pipe_through :browser

    get "/", PageController, :home

    # AshAuthentication routes
    auth_routes AuthController, Ashcrud.Accounts.User, path: "/auth"
    sign_out_route AuthController

    sign_in_route(
      register_path: "/register",
      reset_path: "/reset",
      auth_routes_prefix: "/auth",
      on_mount: [{AshcrudWeb.LiveUserAuth, :live_no_user}],
      overrides: [
        AshcrudWeb.AuthOverrides,
        Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI
      ]
    )

    reset_route(
      auth_routes_prefix: "/auth",
      overrides: [
        AshcrudWeb.AuthOverrides,
        Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI
      ]
    )

    confirm_route Ashcrud.Accounts.User, :confirm_new_user,
      auth_routes_prefix: "/auth",
      overrides: [AshcrudWeb.AuthOverrides, Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI]

    magic_sign_in_route(Ashcrud.Accounts.User, :magic_link,
      auth_routes_prefix: "/auth",
      overrides: [AshcrudWeb.AuthOverrides, Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI]
    )
  end

  # Development only routes
  if Application.compile_env(:ashcrud, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AshcrudWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    import AshAdmin.Router

    scope "/admin" do
      pipe_through :browser

      ash_admin "/"
    end
  end
end
