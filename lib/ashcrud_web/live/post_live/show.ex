defmodule AshcrudWeb.PostLive.Show do
  use AshcrudWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Post {@post.id}
        <:subtitle>This is a post record from your database.</:subtitle>

        <:actions>
          <.button_link navigate={~p"/posts"}>
            <.icon name="hero-arrow-left" />
          </.button_link>
          <.button_link variant="primary" navigate={~p"/posts/#{@post}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit Post
          </.button_link>
        </:actions>
      </.header>

      <.list>
        <:item title="Id">{@post.id}</:item>

        <:item title="Title">{@post.title}</:item>

        <:item title="Content">{@post.content}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Post")
     |> assign(:post, Ash.get!(Blog.Post, id))}
  end
end
