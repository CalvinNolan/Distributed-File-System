defmodule SecurityService.AuthView do
  use SecurityService.Web, :view
  alias Poison, as: JSON

  def render("logOut.json", %{message: message}) do
    encrypt_response(%{
      result: true,
      message: message
    })
  end

  def render("failure.json", %{message: message}) do
    encrypt_response(%{
      result: false,
      message: message
    })
  end

  def render("success.json", %{user: user, token: token}) do
    encrypt_response(%{
      result: true,
      user_id: user.id,
      username: user.username,
      token: token
    })
  end

  def render("success_username.json", %{uid: uid}) do
    encrypt_response(%{
      result: true,
      user_id: uid
    })
  end

  def encrypt_response(map) do
    Base.url_encode64(JSON.encode!(map))
  end
end
