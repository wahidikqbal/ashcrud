defmodule AshcrudWeb.ItemLive.Index do
  use AshcrudWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page={@current_page}>
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
            phx-click={
              JS.push("confirm_delete", value: %{id: item.id})
              |> show_modal("delete-modal")
            }
          >
            Delete
          </.link>
        </:action>
      </.table>

      <.modal id="delete-modal" title="Confirm Delete">
        <div class="space-y-4">
          <p class="text-sm text-gray-600">
            Are you sure you want to delete this item?
            This action cannot be undone.
          </p>

          <div class="flex justify-end gap-2">
            <button
              phx-click={hide_modal("delete-modal")}
              class="px-4 py-2 text-sm rounded-lg border border-gray-300 hover:bg-gray-100 transition"
            >
              Cancel
            </button>

            <button
              phx-click={
                JS.push("delete", value: %{id: @delete_id})
                |> hide_modal("delete-modal")
              }
              class="px-4 py-2 text-sm rounded-lg bg-red-600 text-white hover:bg-red-700 transition"
            >
              Delete
            </button>
          </div>
        </div>
      </.modal>

    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Items")
     |> assign(:current_page, ~p"/items")
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:delete_id, nil)
     |> stream(:items, Ash.read!(Product.Item, load: [:material, :suppliers, :user], actor: socket.assigns[:current_user]))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    item = Ash.get!(Product.Item, id, actor: socket.assigns.current_user)
    Ash.destroy!(item, actor: socket.assigns.current_user)

    {:noreply,
    socket
    |> assign(:delete_id, nil)
    |> push_event("js-exec", %{to: "#delete-modal", attr: "data-hide"})
    |> stream_delete(:items, item)}
  end

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, :delete_id, id)}
  end

  @impl true
  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, :delete_id, nil)}
  end
end
