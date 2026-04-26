defmodule AshcrudWeb.PostLive.Index do
  use AshcrudWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page={@current_page}>
      <.header>
        <h1 class="text-3xl font-semibold leading-tight">Posts</h1>
        <:actions>
          <.button_link variant="primary" navigate={~p"/posts/new"}>
            <.icon name="hero-plus" /> New Post
          </.button_link>
        </:actions>
      </.header>

      <.table
        id="posts"
        variant="base_hoverable"
        color=""
        padding="medium"
        rows_border="extra_small"
        text_size="small"
        class="w-full p-4 border border-gray-200 rounded-lg"
      >
        <:header>ID</:header>
        <:header>Title</:header>
        <:header>Content</:header>
        <:header>Aksi</:header>

        <tbody id="posts-stream" phx-update="stream">
          <%= for {id, post} <- @streams.posts do %>
            <.tr id={id} phx-click={JS.navigate(~p"/posts/#{post}")} class="cursor-pointer">
              <.td>{post.id}</.td>
              <.td>
                <.link navigate={~p"/posts/#{post}"} class="hover:underline">
                  {post.title}
                </.link>
              </.td>
              <.td>{post.content}</.td>
              <.td>
                <div class="flex gap-3">
                  <.link
                    navigate={~p"/posts/#{post}/edit"}
                    class="text-indigo-600 hover:text-indigo-900"
                  >
                    Edit
                  </.link>
                  <.link
                    phx-click={JS.push("delete", value: %{id: post.id}) |> hide("##{id}")}
                    data-confirm="Are you sure?"
                    class="text-red-600 hover:text-red-900"
                  >
                    Delete
                  </.link>
                </div>
              </.td>
            </.tr>
          <% end %>
        </tbody>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Posts")
     |> assign(:current_page, ~p"/posts")
     |> assign(:current_user, socket.assigns.current_user)
     |> stream(:posts, Ash.read!(Blog.Post))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Ash.get!(Blog.Post, id)
    Ash.destroy!(post)

    {:noreply, stream_delete(socket, :posts, post)}
  end
end
