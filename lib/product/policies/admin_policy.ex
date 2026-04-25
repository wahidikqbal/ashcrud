defmodule Product.Policies.AdminPolicy do
  defmacro __using__(_opts) do
    quote location: :keep do
      policies do
        # Admin full akses - bypass semua policy lain jika admin
        bypass actor_present() do
          authorize_if expr(^actor(:role) == :admin)
        end

        # Non-admin: tidak ada akses apa pun (create, update, destroy, read)
        # Semua action akan ditolak karena tidak ada policy yang authorize
        # (bypass di atas sudah menangkap admin, sisanya otomatis forbid)
      end
    end
  end
end