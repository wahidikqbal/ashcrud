defmodule AshcrudWeb.MaterialLive.Form do
  use AshcrudWeb, :live_view
  on_mount {AshcrudWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage material records in your database.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="material-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />

        <.button phx-disable-with="Saving..." variant="primary">Save Material</.button>
        <.button_link navigate={return_path(@return_to, @material)}>Cancel</.button_link>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    material =
      case params["id"] do
        nil -> nil
        id -> Ash.get!(Product.Material, id, actor: socket.assigns.current_user)
      end

    action = if is_nil(material), do: "New", else: "Edit"
    page_title = action <> " " <> "Material"

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(material: material)
     |> assign(:page_title, page_title)
     |> assign_form()}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  @impl true
  def handle_event("validate", %{"material" => material_params}, socket) do
    {:noreply,
     assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, material_params))}
  end

  def handle_event("save", %{"material" => material_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: material_params) do
      {:ok, material} ->
        socket =
          socket
          |> put_flash(:info, "Material #{socket.assigns.form.source.type}d successfully")
          |> push_navigate(to: return_path(socket.assigns.return_to, material))

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp assign_form(%{assigns: %{material: material}} = socket) do
    form =
      if material do
        AshPhoenix.Form.for_update(material, :update,
          as: "material",
          actor: socket.assigns.current_user
        )
      else
        AshPhoenix.Form.for_create(Product.Material, :create,
          as: "material",
          actor: socket.assigns.current_user
        )
      end

    assign(socket, form: to_form(form))
  end

  defp return_path("index", _material), do: ~p"/materials"
  defp return_path("show", material), do: ~p"/materials/#{material.id}"
end
