defmodule DirectoryService.DirectoryView do
  use DirectoryService.Web, :view
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

  def render("success_list_files.json", %{files: files}) do 
  	encrypt_response(%{
  		result: true,
  		files: files
  	})
  end

  def encrypt_response(map) do
    Base.url_encode64(JSON.encode!(map))
  end
end
