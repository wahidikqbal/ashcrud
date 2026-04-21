# lib/product/policies/owner_policy.ex
defmodule Product.Policies.OwnerPolicy do
  defmacro __using__(_opts) do
    quote do
      policies do

        policy action_type(:read) do
          authorize_if relates_to_actor_via(:user)
          authorize_if expr(^actor(:role) == :admin)
        end

        policy action_type(:create) do
          authorize_if actor_present()
          authorize_if expr(^actor(:role) == :admin)
        end

        policy action_type(:update) do
          authorize_if relates_to_actor_via(:user)
          authorize_if expr(^actor(:role) == :admin)
        end

        policy action_type(:destroy) do
          authorize_if relates_to_actor_via(:user)
          authorize_if expr(^actor(:role) == :admin)
        end
      end
    end
  end
end