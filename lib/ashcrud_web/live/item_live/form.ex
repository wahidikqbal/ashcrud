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

        <.button phx-disable-with="Saving..." variant="primary">Save Item</.button>
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
        id -> Ash.get!(Product.Item, id, actor: socket.assigns.current_user)
      end
      
    materials = 
      Product.Material
      |> Ash.read!(actor: socket.assigns.current_user)
      |> Enum.map(fn m -> {m.name, m.id} end)
    
      action = if is_nil(item), do: "New", else: "Edit"
    page_title = action <> " " <> "Item"


    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(item: item)
     |> assign(:materials, materials)
     |> assign(:page_title, page_title)
     |> assign_form()}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  @impl true
  def handle_event("validate", %{"item" => item_params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, item_params))}
  end

  def handle_event("save", %{"item" => item_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: item_params) do
      {:ok, item} ->
        socket =
          socket
          |> put_flash(:info, "Item #{socket.assigns.form.source.type}d successfully")
          |> push_navigate(to: return_path(socket.assigns.return_to, item))

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp assign_form(%{assigns: %{item: item}} = socket) do
    form =
      if item do
        AshPhoenix.Form.for_update(item, :update, as: "item", actor: socket.assigns.current_user)
      else
        AshPhoenix.Form.for_create(Product.Item, :create,
          as: "item",
          actor: socket.assigns.current_user
        )
      end

    assign(socket, form: to_form(form))
  end

  defp return_path("index", _item), do: ~p"/items"
  defp return_path("show", item), do: ~p"/items/#{item.id}"
end
