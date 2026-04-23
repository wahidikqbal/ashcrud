defmodule AshcrudWeb.ItemLive.Show do
  use AshcrudWeb, :live_view
  on_mount {AshcrudWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page={@current_page}>
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

        <:item title="Supplier">
          <%= if Enum.empty?(@item.suppliers) do %>
            N/A
          <% else %>
            <%= for supplier <- @item.suppliers do %>
              <div><%= supplier.name %></div>
            <% end %>
          <% end %>
        </:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Item")
     |> assign(:current_page, ~p"/items/#{id}")
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:item, Ash.get!(Product.Item, id, load: [:material, :suppliers], actor: socket.assigns.current_user))}
  end
end
