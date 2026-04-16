defmodule AshcrudWeb.ItemLive.Form do
  use AshcrudWeb, :live_view
  on_mount {AshcrudWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage item records in your database.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="item-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" /><.input
          field={@form[:code]}
          type="text"
          label="Code"
        />

        <.input
          field={@form[:material_id]}
          type="select"
          label="Material"
          options={@materials}
        />

        <.input
          field={@form[:supplier_ids]}
          type="select"
          multiple={true}
          label="Suppliers"
          options={@suppliers}
          value={@selected_supplier_ids}
        />

        <.button type="button" phx-click="submit_form" phx-disable-with="Saving..." variant="primary">Save Item</.button>
        <.button_link navigate={return_path(@return_to, @item)}>Cancel</.button_link>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    item =
      case params["id"] do
        nil -> nil
        id -> 
          Ash.get!(Product.Item, id, actor: socket.assigns.current_user)
      end
    
    selected_supplier_ids = if item do
      item_id = if is_integer(item.id), do: item.id, else: String.to_integer(item.id)
      
      Product.ItemSupplier
      |> Ash.read!()
      |> Enum.filter(fn is -> is.item_id == item_id end)
      |> Enum.map(& &1.supplier_id)
    else
      []
    end
    
    materials = 
      Product.Material
      |> Ash.read!(actor: socket.assigns.current_user)
      |> Enum.map(fn m -> {m.name, m.id} end)
    
    suppliers =
      Product.Supplier
      |> Ash.read!(actor: socket.assigns.current_user)
      |> Enum.map(fn s -> {s.name, s.id} end)
    
    action = if is_nil(item), do: "New", else: "Edit"
    page_title = action <> " " <> "Item"


    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(item: item)
     |> assign(:materials, materials)
     |> assign(:suppliers, suppliers)
     |> assign(:selected_supplier_ids, selected_supplier_ids)
     |> assign(:page_title, page_title)
     |> assign_form()}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  @impl true
  def handle_event("validate", %{"item" => item_params}, socket) do
    supplier_ids = Map.get(item_params, "supplier_ids", [])
    IO.puts("VALIDATE: supplier_ids")
    IO.inspect(supplier_ids)
    {:noreply, assign(socket, :current_supplier_ids, supplier_ids)}
  end

  def handle_event("submit_form", _params, socket) do
    IO.puts("SUBMIT CALLED")
    
    item_params = Map.get(socket.assigns.form.params, "item", %{})
    supplier_ids = socket.assigns[:current_supplier_ids] || []
    
    IO.inspect(supplier_ids, label: "supplier_ids from assign")
    
    item_params_clean = Map.delete(item_params, "supplier_ids")

    case AshPhoenix.Form.submit(socket.assigns.form, params: item_params_clean) do
      {:ok, item} ->
        update_suppliers(item, supplier_ids)

        socket =
          socket
          |> put_flash(:info, "Item #{socket.assigns.form.source.type}d successfully")
          |> push_navigate(to: return_path(socket.assigns.return_to, item))

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp update_suppliers(item, supplier_ids) do
    current = fetch_current_suppliers(item.id)
    current_supplier_ids = (current || []) |> Enum.map(& &1.id)
    
    new_supplier_ids = supplier_ids 
      |> Enum.map(fn sid -> 
        case Integer.parse(to_string(sid)) do
          {num, _} -> num
          :error -> sid
        end
      end)
      |> Enum.reject(&(&1 == nil || &1 == ""))

    to_remove = current_supplier_ids -- new_supplier_ids
    to_add = new_supplier_ids -- current_supplier_ids

    for supplier_id <- to_remove do
      Product.ItemSupplier
      |> Ash.read!()
      |> Enum.filter(fn is -> is.item_id == item.id && is.supplier_id == supplier_id end)
      |> Enum.each(&Ash.destroy!/1)
    end

    for supplier_id <- to_add do
      Product.ItemSupplier
      |> Ash.Changeset.for_create(:create, item_id: item.id, supplier_id: supplier_id)
      |> Ash.create!()
    end

    :ok
  end

  defp fetch_current_suppliers(item_id) do
    item_id_int = if is_integer(item_id), do: item_id, else: String.to_integer(item_id)
    
    item_suppliers = Product.ItemSupplier
    |> Ash.read!()
    |> Enum.filter(fn is -> is.item_id == item_id_int end)
    
    supplier_ids = Enum.map(item_suppliers, & &1.supplier_id)
    
    if supplier_ids != [] do
      Enum.reduce(supplier_ids, [], fn sid, acc ->
        case Ash.get(Product.Supplier, sid) do
          nil -> acc
          supplier -> [supplier | acc]
        end
      end)
    else
      []
    end
  end

  defp assign_form(%{assigns: %{item: item, selected_supplier_ids: selected_supplier_ids}} = socket) do
    form =
      if item do
        AshPhoenix.Form.for_update(item, :update,
          as: "item", 
          actor: socket.assigns.current_user)
      else
        AshPhoenix.Form.for_create(Product.Item, :create,
          as: "item",
          actor: socket.assigns.current_user
        )
      end

    updated_params = Map.merge(form.params, %{"supplier_ids" => selected_supplier_ids})
    form = %{form | params: updated_params}
    
    assign(socket, form: to_form(form))
  end

  defp return_path("index", _item), do: ~p"/items"
  defp return_path("show", item), do: ~p"/items/#{item.id}"
end
