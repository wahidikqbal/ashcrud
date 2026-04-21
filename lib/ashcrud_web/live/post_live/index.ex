defmodule AshcrudWeb.PostLive.Index do
  use AshcrudWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
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
        rows={@streams.posts}
        row_click={fn {_id, post} -> JS.navigate(~p"/posts/#{post}") end}
      >
        <:col :let={{_id, post}} label="Id">{post.id}</:col>

        <:col :let={{_id, post}} label="Title">{post.title}</:col>

        <:col :let={{_id, post}} label="Content">{post.content}</:col>

        <:action :let={{_id, post}}>
          <div class="sr-only">
            <.link navigate={~p"/posts/#{post}"}>Show</.link>
          </div>

          <.link navigate={~p"/posts/#{post}/edit"}>Edit</.link>
        </:action>

        <:action :let={{id, post}}>
          <.link
            phx-click={JS.push("delete", value: %{id: post.id}) |> hide("##{id}")}
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
     |> assign(:page_title, "Listing Posts")
     |> stream(:posts, Ash.read!(Blog.Post))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Ash.get!(Blog.Post, id)
    Ash.destroy!(post)

    {:noreply, stream_delete(socket, :posts, post)}
  end
end
