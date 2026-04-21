defmodule AshcrudWeb.ItemLive.Index do
  use AshcrudWeb, :live_view
  on_mount {AshcrudWeb.LiveUserAuth, :live_user_required}

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

        <:col :let={{_id, item}} label="Supplier">
          <%= if Enum.empty?(item.suppliers) do %>
            N/A
          <% else %>
            <%= for supplier <- item.suppliers do %>
              <div><%= supplier.name %></div>
            <% end %>
          <% end %>
        </:col>

         <:col :let={{_id, item}} label="Created By">
          <%= if item.user do %>
            <%= item.user.email %>
          <% else %>
            N/A
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
    {:ok,
     socket
     |> assign(:page_title, "Listing Items")
     |> assign_new(:current_user, fn -> nil end)
     |> stream(:items, Ash.read!(Product.Item, load: [:material, :suppliers, :user], actor: socket.assigns[:current_user]))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    item = Ash.get!(Product.Item, id, actor: socket.assigns.current_user)
    Ash.destroy!(item, actor: socket.assigns.current_user)

    {:noreply, stream_delete(socket, :items, item)}
  end
end
