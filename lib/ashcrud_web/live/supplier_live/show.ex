defmodule AshcrudWeb.SupplierLive.Show do
  use AshcrudWeb, :live_view
  on_mount {AshcrudWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Supplier {@supplier.id}
        <:subtitle>This is a supplier record from your database.</:subtitle>

        <:actions>
          <.button_link navigate={~p"/suppliers"}>
            <.icon name="hero-arrow-left" />
          </.button_link>
          <.button_link variant="primary" navigate={~p"/suppliers/#{@supplier}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit Supplier
          </.button_link>
        </:actions>
      </.header>

      <.list>
        <:item title="Id">{@supplier.id}</:item>

        <:item title="Name">{@supplier.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Supplier")
     |> assign(:supplier, Ash.get!(Product.Supplier, id))}
  end
end
