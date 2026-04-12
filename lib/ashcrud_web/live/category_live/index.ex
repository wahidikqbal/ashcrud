defmodule AshcrudWeb.CategoryLive.Index do
  use AshcrudWeb, :live_view

  # auth on_mounts are defined in AshcrudWeb.LiveUserAuth
  on_mount {AshcrudWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Categories
        <:actions>
          <.button_link variant="primary" navigate={~p"/categories/new"}>
            <.icon name="hero-plus" /> New Category
          </.button_link>
        </:actions>
      </.header>

      <.table
        id="categories"
        rows={@streams.categories}
        row_click={fn {_id, category} -> JS.navigate(~p"/categories/#{category}") end}
      >
        <:col :let={{_id, category}} label="Id">{category.id}</:col>

        <:col :let={{_id, category}} label="Title">{category.title}</:col>

        <:action :let={{_id, category}}>
          <div class="sr-only">
            <.link navigate={~p"/categories/#{category}"}>Show</.link>
          </div>

          <.link navigate={~p"/categories/#{category}/edit"}>Edit</.link>
        </:action>

        <:action :let={{id, category}}>
          <.link
            phx-click={JS.push("delete", value: %{id: category.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Categories")
     |> assign_new(:current_user, fn -> nil end)
     |> stream(:categories, Ash.read!(Blog.Category, actor: socket.assigns[:current_user]))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = Ash.get!(Blog.Category, id, actor: socket.assigns.current_user)
    Ash.destroy!(category, actor: socket.assigns.current_user)

    {:noreply, stream_delete(socket, :categories, category)}
  end
end
