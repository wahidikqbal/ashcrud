defmodule AshcrudWeb.PostLive.Form do
  use AshcrudWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page={@current_page}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage post records in your database.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="post-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" /><.input
          field={@form[:content]}
          type="text"
          label="Content"
        />

        <.button phx-disable-with="Saving..." variant="primary">Save Post</.button>
        <.button_link navigate={return_path(@return_to, @post)}>Cancel</.button_link>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    post =
      case params["id"] do
        nil -> nil
        id -> Ash.get!(Blog.Post, id)
      end

    action = if is_nil(post), do: "New", else: "Edit"
    page_title = action <> " " <> "Post"

    current_page =
      if post do
        ~p"/posts/#{post}/edit"
      else
        ~p"/posts/new"
      end

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(post: post)
     |> assign(:page_title, page_title)
     |> assign(:current_page, current_page)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign_form()}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, post_params))}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: post_params) do
      {:ok, post} ->
        socket =
          socket
          |> put_flash(:info, "Post #{socket.assigns.form.source.type}d successfully")
          |> push_navigate(to: return_path(socket.assigns.return_to, post))

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp assign_form(%{assigns: %{post: post}} = socket) do
    form =
      if post do
        AshPhoenix.Form.for_update(post, :update, as: "post")
      else
        AshPhoenix.Form.for_create(Blog.Post, :create, as: "post")
      end

    assign(socket, form: to_form(form))
  end

  defp return_path("index", _post), do: ~p"/posts"
  defp return_path("show", post), do: ~p"/posts/#{post.id}"
end
