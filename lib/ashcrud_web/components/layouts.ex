defmodule AshcrudWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AshcrudWeb, :html

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

  attr :sidebar_class, :string,
    default: "",
    doc: "additional CSS classes for the sidebar"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="flex h-screen bg-base-100 overflow-hidden">
      <!-- Sidebar -->
      <aside
        id="admin-sidebar"
        data-sidebar-selector="#admin-sidebar"
        data-minimized="false"
        data-expanded-width="16rem"
        data-collapsed-width="4rem"
        class={[
          "bg-base-200 text-base-content h-full flex flex-col transition-all duration-300 ease-in-out",
          "fixed lg:relative z-50",
          "w-64 -translate-x-full lg:translate-x-0 opacity-0 lg:opacity-100",
          @sidebar_class
        ]}
      >
        <!-- Brand / Logo -->
        <div class="h-16 flex items-center gap-3 px-4 border-b border-base-300 shrink-0">
          <div class="flex items-center gap-2 overflow-hidden whitespace-nowrap" data-item-label>
            <.link href="/" class="flex items-center gap-2 hover:no-underline flex-1 min-w-0">
              <img src={~p"/images/logo.svg"} width="32" height="32" alt="Logo" class="shrink-0" />
              <span class="text-lg font-semibold truncate">Ashcrud</span>
            </.link>
          </div>
          <!-- Minimize button (desktop only) -->
          <button
            id="desktop-sidebar-minimize"
            type="button"
            class="btn btn-ghost btn-sm btn-circle hidden lg:flex ml-auto shrink-0"
            phx-hook="Sidebar"
            data-sidebar-selector="#admin-sidebar"
            aria-label="Toggle sidebar"
          >
            <.icon name="hero-chevron-left" class="minimize-icon w-5 h-5 transition-transform" />
          </button>
        </div>

        <!-- Navigation -->
        <nav id="main-navigation" class="flex-1 overflow-y-auto py-4 px-3 space-y-1">
          <.sidebar_item navigate={~p"/"} icon="hero-home" label="Dashboard" />
          <.sidebar_item
            navigate={~p"/posts"}
            icon="hero-document-text"
            label="Posts"
            active?={@current_page == ~p"/posts"}
          />
          <.sidebar_item
            navigate={~p"/categories"}
            icon="hero-queue-list"
            label="Categories"
            active?={@current_page == ~p"/categories"}
          />
          <.sidebar_item
            navigate={~p"/suppliers"}
            icon="hero-truck"
            label="Suppliers"
            active?={@current_page == ~p"/suppliers"}
          />
          <.sidebar_item
            navigate={~p"/items"}
            icon="hero-cube"
            label="Items"
            active?={@current_page == ~p"/items"}
          />
          <.sidebar_item
            :if={is_admin?(@current_user)}
            navigate={~p"/materials"}
            icon="hero-paint-brush"
            label="Materials"
            active?={@current_page == ~p"/materials"}
          />
        </nav>

        <!-- Bottom Section -->
        <div class="border-t border-base-300 p-4 shrink-0">
          <div class="flex items-center gap-3">
            <div class="avatar placeholder">
              <div class="bg-neutral text-neutral-content rounded-full w-8">
                <span class="text-xs">AI</span>
              </div>
            </div>
            <div class="flex-1 min-w-0" data-item-label>
              <p class="text-sm font-medium truncate">Admin User</p>
              <p class="text-xs text-base-content/60 truncate">admin@example.com</p>
            </div>
          </div>
        </div>
      </aside>

      <!-- Main Content Area -->
      <div class="flex-1 flex flex-col min-w-0">
        <!-- Top Header -->
        <header class="navbar bg-base-100 border-b border-base-300 px-4 sm:px-6 lg:px-8 h-16 shrink-0">
          <div class="flex-1 items-center gap-4">
            <!-- Mobile menu button -->
            <button
              id="mobile-sidebar-toggle"
              type="button"
              class="btn btn-ghost btn-sm btn-circle lg:hidden"
              phx-click={
                JS.exec(
                  "const s = document.getElementById('admin-sidebar');" <>
                  "const hidden = s.classList.contains('-translate-x-full');" <>
                  "if(hidden){" <>
                  "  s.classList.remove('-translate-x-full','opacity-0');" <>
                  "  s.classList.add('translate-x-0','opacity-100');" <>
                  "}else{" <>
                  "  s.classList.remove('translate-x-0','opacity-100');" <>
                  "  s.classList.add('-translate-x-full','opacity-0');" <>
                  "}"
                )
              }
              aria-label="Toggle sidebar"
            >
              <.icon name="hero-bars-3" class="w-5 h-5" />
            </button>

            <.link href="/" class="flex items-center gap-2 text-sm font-semibold hover:no-underline">
              <img src={~p"/images/logo.svg"} width="24" />
              <span class="hidden sm:inline">v{Application.spec(:phoenix, :vsn)}</span>
            </.link>
          </div>

          <div class="flex-none items-center gap-2">
            <ul class="flex items-center px-1 space-x-2">
              <li>
                <.theme_toggle />
              </li>
              <li>
                <a href="https://hexdocs.pm/phoenix/overview.html" class="btn btn-primary btn-sm">
                  Get Started <span aria-hidden="true">&rarr;</span>
                </a>
              </li>
            </ul>
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

  def sidebar_item(assigns) do
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
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/4 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/4 [[data-theme=dark]_&]:left-2/4 [[data-theme=midnight-purple]_&]:left-3/4 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/4"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/4"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/4"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/4"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="midnight-purple"
      >
        <.icon name="hero-stop-circle-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

   # Helper to check admin role
  defp is_admin?(%{role: :admin}), do: true
  defp is_admin?(_), do: false
end
