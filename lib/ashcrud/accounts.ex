defmodule Ashcrud.Accounts do
  use Ash.Domain, otp_app: :ashcrud, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Ashcrud.Accounts.Token
    resource Ashcrud.Accounts.User
  end
end
