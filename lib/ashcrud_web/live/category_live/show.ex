defmodule AshcrudWeb.CategoryLive.Show do
  use AshcrudWeb, :live_view

  # auth on_mounts are defined in AshcrudWeb.LiveUserAuth
  on_mount {AshcrudWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Category {@category.id}
        <:subtitle>This is a category record from your database.</:subtitle>

        <:actions>
          <.button_link navigate={~p"/categories"}>
            <.icon name="hero-arrow-left" />
          </.button_link>
          <.button_link variant="primary" navigate={~p"/categories/#{@category}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit Category
          </.button_link>
        </:actions>
      </.header>

      <.list>
        <:item title="Id">{@category.id}</:item>

        <:item title="Title">{@category.title}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Category")
     |> assign(:category, Ash.get!(Blog.Category, id, actor: socket.assigns.current_user))}
  end
end
