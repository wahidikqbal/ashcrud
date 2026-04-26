defmodule Blog.Category do
  use Ash.Resource, 
    otp_app: :ashcrud,
    domain: Blog,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "categories"
    repo Ashcrud.Repo
  end

  actions do
    defaults [:read, :destroy, create: [:title], update: [:title]]
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      allow_nil? false
      public? true
    end
    
    timestamps()
  end

  identities do
     identity :unique_title, [:title]
  end


  policies do
    policy action_type(:read) do
      authorize_if actor_present()
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type(:update) do
      authorize_if actor_present()
    end

    policy action_type(:destroy) do
      authorize_if actor_present()
    end
  end

end
