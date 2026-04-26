defmodule AshcrudWeb.RequireAdmin do
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    user = socket.assigns[:current_user]

    cond do
      is_nil(user) ->
        {:halt,
         socket
         |> put_flash(:error, "Harus login")
         |> redirect(to: "/sign-in")}

      user.role != :admin ->
        {:halt,
         socket
         |> put_flash(:error, "Tidak punya akses")
         |> redirect(to: "/")}

      true ->
        {:cont, socket}
    end
  end
end