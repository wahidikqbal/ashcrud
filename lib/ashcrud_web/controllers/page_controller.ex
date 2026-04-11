defmodule AshcrudWeb.PageController do
  use AshcrudWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
