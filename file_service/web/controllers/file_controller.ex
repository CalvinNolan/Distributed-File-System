defmodule FileService.FileController do
  use FileService.Web, :controller
  alias FileService.File, as: FileData
  alias Poison, as: JSON
  import Ecto.Query, only: [from: 2]
  import FileService.ErrorHelpers

  def index(conn, _user_params) do
    render conn, "success.json", message: "Hello."
  end

  def read_file(conn, user_params) do
    render conn, "success.json", message: "read file."
  end

  # Takes in a file and saves it.
  def write_file(conn, user_params) do    
    conn = conn 
        |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:file_service, FileService.Endpoint)[:directory_service_host])
        |> put_resp_header("Access-Control-Allow-Credentials", "true")
        |> fetch_session()

    cond do
      Map.has_key?(user_params, "file") ->
        # First extract the owner id from the filename, then check if a directory exists for it.
        [owner_id, filename] = String.split(user_params["file"].filename, "/", parts: 2)
        if not File.dir?("files/" <> owner_id) do
          File.mkdir("files/" <> owner_id)
        end

        # Write the file to the system.
        case File.cp(user_params["file"].path, "files/" <> user_params["file"].filename) do
          :ok ->
            # Add the file details to the database.
            changeset = FileData.changeset(%FileData{}, %{owner_id: String.to_integer(owner_id),
                                                            filename: filename, server: "0",
                                                              content_type: user_params["file"].content_type})

            # Insert new user file in the directory.
            case Repo.insert(changeset) do
              {:ok, user_file} ->
                render conn, "success.json", file_id: user_file.id
              {:error, changeset} ->
                render conn, "failure.json", message: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
            end
          {:error, reason} ->
            render conn, "failure.json", message: reason
        end
      true ->
        render conn, "failure.json", message: "Missing parameters."
    end
  end

  # Decrypts a base 64 string and converts it into a map
  def decrypt_request(request) do
    JSON.decode!(Base.url_decode64!(request))
  end
end
