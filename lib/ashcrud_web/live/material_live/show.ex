defmodule AshcrudWeb.MaterialLive.Show do
  use AshcrudWeb, :live_view
  on_mount {AshcrudWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Material {@material.id}
        <:subtitle>This is a material record from your database.</:subtitle>

        <:actions>
          <.button_link navigate={~p"/materials"}>
            <.icon name="hero-arrow-left" />
          </.button_link>
          <.button_link variant="primary" navigate={~p"/materials/#{@material}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit Material
          </.button_link>
        </:actions>
      </.header>

      <.list>
        <:item title="Id">{@material.id}</:item>

        <:item title="Name">{@material.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Material")
     |> assign(:material, Ash.get!(Product.Material, id, actor: socket.assigns.current_user))}
  end
end
