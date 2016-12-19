defmodule DirectoryService.DirectoryController do
  use DirectoryService.Web, :controller
  alias DirectoryService.File
  alias Poison, as: JSON
  import Ecto.Query, only: [from: 2]
  import DirectoryService.ErrorHelpers

  def index(conn, _params) do
    render conn, "index.json", message: "hello!"
  end

  def list_files(conn, user_params) do
    conn = conn 
        |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:directory_service, DirectoryService.Endpoint)[:client_service_host])
        |> put_resp_header("Access-Control-Allow-Credentials", "true")
        |> fetch_session()

    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])

        cond do
          Map.has_key?(request_data, "username") and Map.has_key?(request_data, "auth_token") ->
            
            # Request to Security Service to authenticate user request.
            auth_data = Base.url_encode64(JSON.encode!(%{token: request_data["auth_token"], username: request_data["username"]}))
            {:ok, auth_response} = HTTPoison.post "#{Application.get_env(:directory_service, DirectoryService.Endpoint)[:security_service_host]}/authenticate", 
                                                    "{\"data\": \"" <> auth_data <> "\"}", [{"Content-Type", "application/json"}]
            decrypted_auth_response = decrypt_request(String.trim(auth_response.body, "\""))

            cond do
              Map.has_key?(decrypted_auth_response, "result") and decrypted_auth_response["result"] ->
                
                # Get references to all the files this User has access to.
                query = from f in File,
                  where: f.uid == ^(decrypted_auth_response["user_id"]),
                  select: f
                user_files = Repo.all(query)

                if user_files do
                  render conn, "success_list_files.json", files: user_files
                else
                  render conn, "failure.json", message: "No files available for this user."
                end
              true ->
                render conn, "failure.json", message: "Unauthorized."
              end
          true ->
            render conn, "failure.json", message: "Missing parameters."
        end
      true ->
        render conn, "failure.json", message: "Missing parameters."
    end
  end

  def read_file(conn, user_params) do
    
  end

  def write_file(conn, user_params) do
    conn = conn 
        |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:directory_service, DirectoryService.Endpoint)[:client_service_host])
        |> put_resp_header("Access-Control-Allow-Credentials", "true")
        |> fetch_session()

    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])

        cond do
          Map.has_key?(request_data, "username") and Map.has_key?(request_data, "auth_token") and Map.has_key?(user_params, "file_data") ->
            
            # Request to Security Service to authenticate user request.
            auth_data = Base.url_encode64(JSON.encode!(%{token: request_data["auth_token"], username: request_data["username"]}))
            {:ok, auth_response} = HTTPoison.post "#{Application.get_env(:directory_service, DirectoryService.Endpoint)[:security_service_host]}/authenticate", 
                                                    "{\"data\": \"" <> auth_data <> "\"}", [{"Content-Type", "application/json"}]
            decrypted_auth_response = decrypt_request(String.trim(auth_response.body, "\""))

            cond do
              Map.has_key?(decrypted_auth_response, "result") and decrypted_auth_response["result"] ->
                # Pick a server to store the file.
                # Look at each server currently online and pick the one with the least number of files.

                # Send the file onto the desired server.

                # Add the file details to the server.
                changeset = File.changeset(%File{}, %{uid: decrypted_auth_response["user_id"], 
                                                        owner_id: decrypted_auth_response["user_id"],
                                                          owner_name: decrypted_auth_response["username"],
                                                          filename: user_params["file_data"].filename, server: "0"})

                # Insert new user file in the directory.
                case Repo.insert(changeset) do
                  {:ok, user_file} ->
                    render conn, "success.json", message: "File Successfully Written"
                  {:error, changeset} ->
                    render conn, "failure.json", message: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
                end
              true ->
                render conn, "failure.json", message: "Unauthorized."
              end
          true ->
            render conn, "failure.json", message: "Missing parameters."
        end
      true ->
        render conn, "failure.json", message: "Missing parameters."
    end
  end

  def share_file(conn, user_params) do
    
  end

  def register_file_server(conn, user_params) do
    
  end

  # Decrypts a base 64 string and converts it into a map
  def decrypt_request(request) do
    JSON.decode!(Base.url_decode64!(request))
  end
end
