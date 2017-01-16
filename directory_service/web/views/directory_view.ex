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

  def render("success.json", %{binary_file_data: binary_file_data}) do
    %{
      body: binary_file_data
    }
  end

  def render("success.json", %{server_id: server_id}) do
    encrypt_response(%{
      result: true,
      server_id: server_id
    })
  end

  def render("success_list_files.json", %{files: files, locks: locks}) do 
  	encrypt_response(%{
  		result: true,
  		files: files,
      locks: locks
  	})
  end

  def render("has_access.json", %{has_access: has_access}) do 
    encrypt_response(%{
      result: true,
      has_access: has_access
    })
  end

  def render("has_access_id.json", %{has_access: has_access, file_id: file_id}) do 
    encrypt_response(%{
      result: true,
      has_access: has_access,
      file_id: file_id
    })
  end

  def encrypt_response(map) do
    Base.url_encode64(JSON.encode!(map))
  end
end
