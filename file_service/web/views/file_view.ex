defmodule FileService.FileView do
  use FileService.Web, :view
  alias Poison, as: JSON

  def render("failure.json", %{message: message}) do
    encrypt_response(%{
      result: false,
      message: message
    })
  end

  def render("success.json", %{file_id: file_id}) do
    IO.puts "success"
    encrypt_response(%{
      result: true,
      file_id: file_id
    })
  end

  def encrypt_response(map) do
    Base.url_encode64(JSON.encode!(map))
  end
end
