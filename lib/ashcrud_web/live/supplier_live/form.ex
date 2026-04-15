defmodule AshcrudWeb.SupplierLive.Form do
  use AshcrudWeb, :live_view
  on_mount {AshcrudWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage supplier records in your database.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="supplier-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />

        <.button phx-disable-with="Saving..." variant="primary">Save Supplier</.button>
        <.button_link navigate={return_path(@return_to, @supplier)}>Cancel</.button_link>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    supplier =
      case params["id"] do
        nil -> nil
        id -> Ash.get!(Product.Supplier, id)
      end

    action = if is_nil(supplier), do: "New", else: "Edit"
    page_title = action <> " " <> "Supplier"

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(supplier: supplier)
     |> assign(:page_title, page_title)
     |> assign_form()}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  @impl true
  def handle_event("validate", %{"supplier" => supplier_params}, socket) do
    {:noreply,
     assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, supplier_params))}
  end

  def handle_event("save", %{"supplier" => supplier_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: supplier_params) do
      {:ok, supplier} ->
        socket =
          socket
          |> put_flash(:info, "Supplier #{socket.assigns.form.source.type}d successfully")
          |> push_navigate(to: return_path(socket.assigns.return_to, supplier))

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp assign_form(%{assigns: %{supplier: supplier}} = socket) do
    form =
      if supplier do
        AshPhoenix.Form.for_update(supplier, :update, as: "supplier")
      else
        AshPhoenix.Form.for_create(Product.Supplier, :create, as: "supplier")
      end

    assign(socket, form: to_form(form))
  end

  defp return_path("index", _supplier), do: ~p"/suppliers"
  defp return_path("show", supplier), do: ~p"/suppliers/#{supplier.id}"
end
