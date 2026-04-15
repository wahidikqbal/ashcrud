defmodule AshcrudWeb.SupplierLive.Index do
  use AshcrudWeb, :live_view
  on_mount {AshcrudWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Suppliers
        <:actions>
          <.button_link variant="primary" navigate={~p"/suppliers/new"}>
            <.icon name="hero-plus" /> New Supplier
          </.button_link>
        </:actions>
      </.header>

      <.table
        id="suppliers"
        rows={@streams.suppliers}
        row_click={fn {_id, supplier} -> JS.navigate(~p"/suppliers/#{supplier}") end}
      >
        <:col :let={{_id, supplier}} label="Id">{supplier.id}</:col>

        <:col :let={{_id, supplier}} label="Name">{supplier.name}</:col>

        <:action :let={{_id, supplier}}>
          <div class="sr-only">
            <.link navigate={~p"/suppliers/#{supplier}"}>Show</.link>
          </div>

          <.link navigate={~p"/suppliers/#{supplier}/edit"}>Edit</.link>
        </:action>

        <:action :let={{id, supplier}}>
          <.link
            phx-click={JS.push("delete", value: %{id: supplier.id}) |> hide("##{id}")}
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
     |> assign(:page_title, "Listing Suppliers")
     |> stream(:suppliers, Ash.read!(Product.Supplier))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    supplier = Ash.get!(Product.Supplier, id)
    Ash.destroy!(supplier)

    {:noreply, stream_delete(socket, :suppliers, supplier)}
  end
end
