defmodule RegistryService.RegistryView do
  use RegistryService.Web, :view
  alias Poison, as: JSON

  def render("success.json", %{service: service, hostname: hostname}) do
    encrypt_response(%{
      result: true,
      service: service,
      hostname: hostname
    })
  end

  def render("failure.json", %{message: message}) do
    encrypt_response(%{
      result: false,
      message: message
    })
  end

  def encrypt_response(map) do
    Base.url_encode64(JSON.encode!(map))
  end
end
