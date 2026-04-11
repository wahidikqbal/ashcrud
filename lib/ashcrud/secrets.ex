defmodule Ashcrud.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        Ashcrud.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:ashcrud, :token_signing_secret)
  end
end
