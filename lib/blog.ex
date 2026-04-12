defmodule Blog do
  use Ash.Domain,
    otp_app: :ashcrud

  resources do
    resource Blog.Post
    resource Blog.Category
  end
end
