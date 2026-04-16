defmodule AshcrudWeb.ItemLive.Index do
  use AshcrudWeb, :live_view
  on_mount {AshcrudWeb.LiveUserAuth, :live_user_required}

  alias Product.ItemSupplier

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Items
        <:actions>
          <.button_link variant="primary" navigate={~p"/items/new"}>
            <.icon name="hero-plus" /> New Item
          </.button_link>
        </:actions>
      </.header>

      <.table
        id="items"
        rows={@streams.items}
        row_click={fn {_id, item} -> JS.navigate(~p"/items/#{item}") end}
      >
        <:col :let={{_id, item}} label="Id">{item.id}</:col>

        <:col :let={{_id, item}} label="Name">{item.name}</:col>

        <:col :let={{_id, item}} label="Code">{item.code}</:col>

        <:col :let={{_id, item}} label="Material">
          <%= if item.material do %>
            <%= item.material.name %>
          <% else %>
            N/A
          <% end %>
        </:col>

        <:col :let={{_id, item}} label="Suppliers">
          <%= if item.suppliers && item.suppliers != [] do %>
            <div class="flex flex-wrap gap-1">
              <%= for supplier <- item.suppliers do %>
                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                  <%= supplier.name %>
                </span>
              <% end %>
            </div>
          <% else %>
            <span class="text-gray-400">-</span>
          <% end %>
        </:col>

        <:action :let={{_id, item}}>
          <div class="sr-only">
            <.link navigate={~p"/items/#{item}"}>Show</.link>
          </div>

          <.link navigate={~p"/items/#{item}/edit"}>Edit</.link>
        </:action>

        <:action :let={{id, item}}>
          <.link
            phx-click={JS.push("delete", value: %{id: item.id}) |> hide("##{id}")}
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
    current_user = socket.assigns[:current_user]
    
    items = if current_user do
      Ash.read!(Product.Item, load: [:material], actor: current_user)
    else
      []
    end
    
    items_with_suppliers = Enum.map(items, fn item ->
      suppliers = fetch_suppliers_for_item(item.id)
      Map.put(item, :suppliers, suppliers)
    end)
    
    {:ok,
     socket
     |> assign(:page_title, "Listing Items")
     |> stream(:items, items_with_suppliers)}
  end

  defp fetch_suppliers_for_item(item_id) do
    try do
      item_id_int = if is_integer(item_id), do: item_id, else: String.to_integer(item_id)
      
      Product.ItemSupplier
      |> Ash.read!()
      |> Enum.filter(fn is -> is.item_id == item_id_int end)
      |> Enum.map(&Ash.get!(Product.Supplier, &1.supplier_id))
    rescue
      _ -> []
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    item = Ash.get!(Product.Item, id, actor: socket.assigns.current_user)
    
    Product.ItemSupplier
    |> Ash.read!()
    |> Enum.filter(fn is -> is.item_id == item.id end)
    |> Enum.each(&Ash.destroy!/1)
    
    Ash.destroy!(item, actor: socket.assigns.current_user)

    {:noreply, stream_delete(socket, :items, item)}
  end
end
