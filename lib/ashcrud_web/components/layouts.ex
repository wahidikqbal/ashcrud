defmodule AshcrudWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AshcrudWeb, :html

  alias AshcrudWeb.Components.PhiaSidebar, as: UISidebar
  alias AshcrudWeb.Components.PhiaButton
  import AshcrudWeb.Components.Icon
  alias Phoenix.LiveView.JS

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  # ============================================================================
  # Layouts.app component attrs
  # ============================================================================
  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples:

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :current_page, :any,
    default: nil,
    doc: "the current page path for active navigation highlighting"

  attr :current_user, :any,
    default: nil,
    doc: "the current authenticated user"

  attr :sidebar_minimized, :boolean,
    default: false,
    doc: "whether the sidebar is in minimized state"

  attr :sidebar_mobile_open, :boolean,
    default: false,
    doc: "whether the sidebar is open on mobile (overlay)"

  attr :sidebar_class, :string,
    default: "",
    doc: "additional CSS classes for the sidebar"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="flex h-screen bg-base-100 overflow-hidden">
      <!-- PhiaUI Sidebar -->
      <UISidebar.sidebar 
        variant={:default} 
        minimized={@sidebar_minimized}
        mobile_open={@sidebar_mobile_open}
        toggleable={true}
      >
        <:brand>
          <.link href="/" class="flex items-center gap-2 hover:no-underline">
            <img src={~p"/images/logo.svg"} width="32" height="32" alt="Logo" class="shrink-0" />
            <span class={["text-lg font-semibold truncate sidebar-brand-text", @sidebar_minimized && "hidden md:hidden"]}>Ashcrud</span>
          </.link>
        </:brand>
        <:nav_items>
          <UISidebar.sidebar_section minimized={@sidebar_minimized} label="Main Menu">
            <UISidebar.sidebar_item minimized={@sidebar_minimized} navigate={~p"/"} active={@current_page == ~p"/"}>
              <:icon><.icon name="hero-home" class="w-5 h-5" /></:icon>
              Dashboard
            </UISidebar.sidebar_item>
            <UISidebar.sidebar_item minimized={@sidebar_minimized} navigate={~p"/posts"} active={@current_page == ~p"/posts"}>
              <:icon><.icon name="hero-document-text" class="w-5 h-5" /></:icon>
              Posts
            </UISidebar.sidebar_item>
            <UISidebar.sidebar_item minimized={@sidebar_minimized} navigate={~p"/categories"} active={@current_page == ~p"/categories"}>
              <:icon><.icon name="hero-folder" class="w-5 h-5" /></:icon>
              Categories
            </UISidebar.sidebar_item>
            <UISidebar.sidebar_item minimized={@sidebar_minimized} navigate={~p"/suppliers"} active={@current_page == ~p"/suppliers"}>
              <:icon><.icon name="hero-truck" class="w-5 h-5" /></:icon>
              Suppliers
            </UISidebar.sidebar_item>
            <UISidebar.sidebar_item minimized={@sidebar_minimized} navigate={~p"/items"} active={@current_page == ~p"/items"}>
              <:icon><.icon name="hero-cube" class="w-5 h-5" /></:icon>
              Items
            </UISidebar.sidebar_item>
            <UISidebar.sidebar_item :if={admin?(@current_user)} minimized={@sidebar_minimized} navigate={~p"/materials"} active={@current_page == ~p"/materials"}>
              <:icon><.icon name="hero-beaker" class="w-5 h-5" /></:icon>
              Materials
            </UISidebar.sidebar_item>
          </UISidebar.sidebar_section>
        </:nav_items>
        <:footer_items>
          <UISidebar.sidebar_item :if={admin?(@current_user)} minimized={@sidebar_minimized} navigate={~p"/admin"} active={@current_page == ~p"/admin"}>
            <:icon><.icon name="hero-cog" class="w-5 h-5" /></:icon>
            Admin
          </UISidebar.sidebar_item>
        </:footer_items>
      </UISidebar.sidebar>

      <!-- Main Content Area -->
      <div class="flex-1 flex flex-col min-w-0 bg-background">
        <!-- Top Header -->
        <header class="border-b border-sidebar-border bg-background px-4 sm:px-6 lg:px-8 h-16 shrink-0 flex items-center justify-between">
          <div class="flex items-center gap-2">
            <!-- Mobile hamburger button (only visible on mobile) -->
            <button
              type="button"
              class="md:hidden p-2 rounded-md hover:bg-base-200"
              data-sidebar-mobile-btn
              onclick="SidebarToggle.toggleMobile()"
              aria-label="Toggle sidebar"
            >
              <.icon name="hero-bars-3" class="w-6 h-6" />
            </button>

            <.link href="/" class="flex items-center gap-2 text-sm font-semibold hover:no-underline">
              <img src={~p"/images/logo.svg"} width="24" class="hidden sm:block" />
              <span class="hidden sm:inline">v{Application.spec(:phoenix, :vsn)}</span>
            </.link>
          </div>

          <div class="flex items-center gap-4">
            <.theme_toggle />
          </div>
        </header>

        <!-- Page Content -->
        <main class="flex-1 overflow-y-auto px-4 py-6 sm:px-6 lg:px-8 bg-base-100">
          <div class="mx-auto max-w-6xl space-y-4">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  # ============================================================================
  # Sidebar navigation item component
  @doc """
  Renders a navigation item for the admin sidebar.
  """
  attr :navigate, :any, required: true, doc: "Navigation target (live navigate)"
  attr :icon, :string, required: true, doc: "Heroicon name (without hero- prefix)"
  attr :label, :string, required: true, doc: "Navigation label text"
  attr :active?, :boolean, default: false, doc: "Whether this item is active"

  # Allow arbitrary attrs (like phx-click) to be passed to the link
  attr :rest, :global, doc: "Additional HTML attributes for the link"

  def phia_sidebar_item(assigns) do
    ~H"""
    <li>
      <.link
        navigate={@navigate}
        class={[
          "flex items-center gap-3 px-3 py-2 rounded-lg transition-colors",
          "hover:bg-base-300 hover:text-base-content",
          @active? && "bg-primary/10 text-primary font-medium"
        ]}
        {@rest}
      >
        <span class="shrink-0">
          <.icon name={@icon} class="w-5 h-5" />
        </span>
        <span class="truncate">{@label}</span>
      </.link>
    </li>
    """
  end

  # ============================================================================
  # Flash group component
  # ============================================================================
  @doc """
  Shows the flash group with standard titles and content.

  ## Examples:

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  # ============================================================================
  # Theme toggle component
  # ============================================================================
  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="flex items-center gap-1 p-1 bg-base-200 rounded-lg">
      <PhiaButton.button
        variant={:ghost}
        size={:sm}
        class="p-2"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        aria-label="System theme"
      >
        <.icon name="hero-computer-desktop" class="w-4 h-4" />
      </PhiaButton.button>

      <PhiaButton.button
        variant={:ghost}
        size={:sm}
        class="p-2"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        aria-label="Light theme"
      >
        <.icon name="hero-sun" class="w-4 h-4" />
      </PhiaButton.button>

      <PhiaButton.button
        variant={:ghost}
        size={:sm}
        class="p-2"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        aria-label="Dark theme"
      >
        <.icon name="hero-moon" class="w-4 h-4" />
      </PhiaButton.button>

      <PhiaButton.button
        variant={:ghost}
        size={:sm}
        class="p-2"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="midnight-purple"
        aria-label="Midnight purple theme"
      >
        <.icon name="hero-sparkles" class="w-4 h-4" />
      </PhiaButton.button>
    </div>
    """
  end

  defp admin?(current_user) do
    current_user && current_user.role == :admin
  end
end
