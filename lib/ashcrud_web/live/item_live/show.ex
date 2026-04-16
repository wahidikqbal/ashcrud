defmodule AshcrudWeb.ItemLive.Show do
  use AshcrudWeb, :live_view
  on_mount {AshcrudWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Item {@item.id}
        <:subtitle>This is a item record from your database.</:subtitle>

        <:actions>
          <.button_link navigate={~p"/items"}>
            <.icon name="hero-arrow-left" />
          </.button_link>
          <.button_link variant="primary" navigate={~p"/items/#{@item}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit Item
          </.button_link>
        </:actions>
      </.header>

      <.list>
        <:item title="Id">{@item.id}</:item>

        <:item title="Name">{@item.name}</:item>

        <:item title="Code">{@item.code}</:item>

        <:item title="Material">
          <%= if @item.material do %>
            <%= @item.material.name %>
          <% else %>
            N/A
          <% end %>
        </:item>

        <:item title="Suppliers">
          <%= if @item.suppliers && @item.suppliers != [] do %>
            <div class="flex flex-wrap gap-2">
              <%= for supplier <- @item.suppliers do %>
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-sm font-medium bg-blue-100 text-blue-800">
                  <%= supplier.name %>
                </span>
              <% end %>
            </div>
          <% else %>
            <span class="text-gray-400">-</span>
          <% end %>
        </:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    current_user = socket.assigns.current_user
    item = Ash.get!(Product.Item, id, load: [:material], actor: current_user)
    suppliers = fetch_suppliers_for_item(id)
    item_with_suppliers = Map.put(item, :suppliers, suppliers)
    
    {:ok,
     socket
     |> assign(:page_title, "Show Item")
     |> assign(:item, item_with_suppliers)}
  end

  defp fetch_suppliers_for_item(item_id) do
    try do
      item_id_int = String.to_integer(item_id)
      
      Product.ItemSupplier
      |> Ash.read!()
      |> Enum.filter(fn is -> is.item_id == item_id_int end)
      |> Enum.map(fn is ->
        Ash.get!(Product.Supplier, is.supplier_id)
      end)
    rescue
      _ -> []
    end
  end
end
