defmodule AshcrudWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  import Phoenix.Component
  import Phoenix.LiveView
  use AshcrudWeb, :verified_routes

  # This is used for nested liveviews to fetch the current user.
  # To use, place the following at the top of that liveview:
  # on_mount {AshcrudWeb.LiveUserAuth, :current_user}
  def on_mount(:current_user, _params, session, socket) do
    # First assign current_user from session
    {:cont, socket} = AshAuthentication.Phoenix.LiveSession.assign_new_resources(socket, session)

    # Then load the role field if user exists
    case socket.assigns[:current_user] do
      nil ->
        {:cont, socket}

      user ->
        case Ash.load(user, [:role]) do
          {:ok, loaded_user} -> {:cont, assign(socket, :current_user, loaded_user)}
          {:error, _reason} ->
            # If we can't load the role, the user may not have proper permissions.
            # Log them out and redirect to sign-in to prevent authorization bypass.
            socket =
              socket
              |> Phoenix.LiveView.put_flash(:error, "Sesi tidak valid, silakan login kembali")
              |> Phoenix.LiveView.clear_session()

            {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
        end
    end
  end

  def on_mount(:live_user_optional, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:live_user_required, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
    end
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end
end
