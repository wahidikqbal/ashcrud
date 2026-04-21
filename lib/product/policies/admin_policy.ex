defmodule Product.Policies.AdminPolicy do
  defmacro __using__(_opts) do
    quote location: :keep do
      policies do
            # Admin full akses
            bypass actor_present() do
                authorize_if expr(^actor(:role) == :admin)
            end

            # Allow reading for any authenticated user for public data
            policy action_type(:read) do
                authorize_if actor_present()
            end

            policy action_type(:create) do
                forbid_if always()
            end

            policy action_type(:update) do
                forbid_if always()
            end

            policy action_type(:destroy) do
                forbid_if always()
            end

        end
    end
  end
end