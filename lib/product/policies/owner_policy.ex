# lib/product/policies/owner_policy.ex
defmodule Product.Policies.OwnerPolicy do
  defmacro __using__(_opts) do
    quote do
      policies do
        policy action_type(:read) do
          authorize_if relates_to_actor_via(:user)
        end

        policy action_type(:create) do
          authorize_if actor_present()
        end

        policy action_type(:update) do
          authorize_if relates_to_actor_via(:user)
        end

        policy action_type(:destroy) do
          authorize_if relates_to_actor_via(:user)
        end
      end
    end
  end
end