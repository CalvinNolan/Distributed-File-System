defmodule LockService.LockView do
  use LockService.Web, :view
  alias Poison, as: JSON

  def render("failure.json", %{message: message}) do
    encrypt_response(%{
      result: false,
      message: message
    })
  end

  def render("success.json", %{message: message}) do
    encrypt_response(%{
      result: true,
      message: message
    })
  end

  def render("success.json", %{locks: locks}) do
    encrypt_response(%{
      result: true,
      locks: locks
    })
  end

  def render("success.json", %{is_token: is_token}) do
    encrypt_response(%{
      result: true,
      is_token: is_token
    })
  end

  def render("success.json", %{token: token}) do
    encrypt_response(%{
      result: true,
      token: token
    })
  end

  def render("success.json", %{is_locked: is_locked}) do
    encrypt_response(%{
      result: true,
      is_locked: is_locked
    })
  end

  def encrypt_response(map) do
    Base.url_encode64(JSON.encode!(map))
  end
end
