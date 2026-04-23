defmodule AshcrudWeb.MaterialLive.Index do
  use AshcrudWeb, :live_view
  on_mount {AshcrudWeb.RequireAdmin, :default}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page={@current_page}>
      <.header>
        Listing Materials
        <:actions>
          <.button_link variant="primary" navigate={~p"/materials/new"}>
            <.icon name="hero-plus" /> New Material
          </.button_link>
        </:actions>
      </.header>

      <.table
        id="materials"
        rows={@streams.materials}
        row_click={fn {_id, material} -> JS.navigate(~p"/materials/#{material}") end}
      >
        <:col :let={{_id, material}} label="Id">{material.id}</:col>

        <:col :let={{_id, material}} label="Name">{material.name}</:col>

        <:action :let={{_id, material}}>
          <div class="sr-only">
            <.link navigate={~p"/materials/#{material}"}>Show</.link>
          </div>

          <.link navigate={~p"/materials/#{material}/edit"}>Edit</.link>
        </:action>

        <:action :let={{id, material}}>
          <.link
            phx-click={JS.push("delete", value: %{id: material.id}) |> hide("##{id}")}
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
     |> assign(:page_title, "Listing Materials")
     |> assign(:current_page, ~p"/materials")
     |> assign(:current_user, socket.assigns.current_user)
     |> stream(:materials, Ash.read!(Product.Material, actor: socket.assigns[:current_user]))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    material = Ash.get!(Product.Material, id, actor: socket.assigns.current_user)
    Ash.destroy!(material, actor: socket.assigns.current_user)

    {:noreply, stream_delete(socket, :materials, material)}
  end
end
