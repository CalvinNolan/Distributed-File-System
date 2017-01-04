defmodule DirectoryService.DirectoryController do
  use DirectoryService.Web, :controller
  alias DirectoryService.File, as: FileData
  alias DirectoryService.Server
  alias Poison, as: JSON
  import Ecto.Query, only: [from: 2]
  import DirectoryService.ErrorHelpers

  # Gets all the files details a given user has access to.
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
                query = from f in FileData,
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

  # Returns a file that the user has access to.
  def read_file(conn, user_params) do
    conn = conn 
        |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:directory_service, DirectoryService.Endpoint)[:client_service_host])
        |> put_resp_header("Access-Control-Allow-Credentials", "true")
        |> fetch_session()

    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])
        cond do
          Map.has_key?(request_data, "username") and Map.has_key?(request_data, "auth_token") and Map.has_key?(request_data, "file_id") ->
            
            # Request to Security Service to authenticate user request.
            auth_data = Base.url_encode64(JSON.encode!(%{token: request_data["auth_token"], username: request_data["username"]}))
            {:ok, auth_response} = HTTPoison.post "#{Application.get_env(:directory_service, DirectoryService.Endpoint)[:security_service_host]}/authenticate", 
                                                    "{\"data\": \"" <> auth_data <> "\"}", [{"Content-Type", "application/json"}]
            decrypted_auth_response = decrypt_request(String.trim(auth_response.body, "\""))

            cond do
              Map.has_key?(decrypted_auth_response, "result") and decrypted_auth_response["result"] ->
                # Ensure this user has access to the file they're requesting to read.
                user_access_query = from f in FileData,
                                    where: f.file_id == ^(request_data["file_id"]) and f.uid == ^(decrypted_auth_response["user_id"]),
                                    select: f
                user_access = Repo.one(user_access_query)

                if user_access do
                  server_data_query = from s in Server,
                                where: s.id == ^(user_access.server)
                  server_data = Repo.one(server_data_query)

                  if server_data do
                    # Read the file from the desired server.
                    read_data = Base.url_encode64(JSON.encode!(%{file_id: request_data["file_id"]}))
                    {:ok, read_response} = HTTPoison.post(server_data.host <> "/read", 
                                                            "{\"data\": \"" <> read_data <> "\"}", 
                                                              [{"Content-Type", "application/json"}])
                    # Send the file contents back to the client.
                    Plug.Conn.send_resp(conn, 200, read_response.body)
                  else
                    render conn, "failure.json", message: "Invalid Internal File Server."
                  end
                else
                  render conn, "failure.json", message: "Invalid Access."
                end
              true ->
                render conn, "failure.json", message: "Unauthorized."
            end
          true ->
            render conn, "failure.json", message: "Missing Parameters."
        end
      true ->
        render conn, "success.json", message: "Missing Parameters."
    end
  end

  # Uploads a new file for a user.
  def write_file(conn, user_params) do
    conn = conn 
        |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:directory_service, DirectoryService.Endpoint)[:client_service_host])
        |> put_resp_header("Access-Control-Allow-Credentials", "true")
        |> fetch_session()

    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])
        cond do
          Map.has_key?(request_data, "username") and Map.has_key?(request_data, "auth_token") and Map.has_key?(user_params, "file_data") and has_file_servers ->
            
            # Request to Security Service to authenticate user request.
            auth_data = Base.url_encode64(JSON.encode!(%{token: request_data["auth_token"], username: request_data["username"]}))
            {:ok, auth_response} = HTTPoison.post "#{Application.get_env(:directory_service, DirectoryService.Endpoint)[:security_service_host]}/authenticate", 
                                                    "{\"data\": \"" <> auth_data <> "\"}", [{"Content-Type", "application/json"}]
            decrypted_auth_response = decrypt_request(String.trim(auth_response.body, "\""))

            cond do
              Map.has_key?(decrypted_auth_response, "result") and decrypted_auth_response["result"] ->
                # Pick a server to store the file.
                file_server = get_file_server

                # Send the file onto the desired server.
                new_filename = "\"" <> to_string(decrypted_auth_response["user_id"]) <> "/" <> user_params["file_data"].filename <> "\""
                {:ok, write_response} = HTTPoison.post(file_server.host <> "/write", {:multipart, [{:file, user_params["file_data"].path, 
                                                          { ["form-data"], [name: "\"file\"", 
                                                                              filename: new_filename]},
                                                                                [{"Content-Type", user_params["file_data"].content_type}]}]})

                write_response = decrypt_request(String.trim(write_response.body, "\""))
                if write_response["result"] do
                  # Add the file details to the directory.
                  changeset = FileData.changeset(%FileData{}, %{uid: decrypted_auth_response["user_id"], 
                                                                  owner_id: decrypted_auth_response["user_id"],
                                                                    owner_name: decrypted_auth_response["username"],
                                                                      filename: user_params["file_data"].filename, 
                                                                        file_id: write_response["file_id"],
                                                                          server: file_server.id})

                  # Insert new user file in the directory.
                  case Repo.insert(changeset) do
                    {:ok, user_file} ->
                      file_server = Ecto.Changeset.change file_server, file_count: (file_server.file_count + 1)
                      case Repo.update(file_server) do
                        {:ok, updated_file_server} ->
                          render conn, "success.json", message: "File Successfully Written"
                        {:error, changeset} ->
                          render conn, "failure.json", message: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
                      end
                    {:error, changeset} ->
                      render conn, "failure.json", message: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
                  end
                else
                  render conn, "failure.json", message: write_response["message"]
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

  # Shares a file with another user given their username.
  def share_file(conn, user_params) do
    # Takes in fileid and username
    conn = conn 
        |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:directory_service, DirectoryService.Endpoint)[:client_service_host])
        |> put_resp_header("Access-Control-Allow-Credentials", "true")
        |> fetch_session()

    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])

        cond do
          Map.has_key?(request_data, "username") and Map.has_key?(request_data, "auth_token") 
            and Map.has_key?(request_data, "share_username") and Map.has_key?(request_data, "file_id") ->
            
            # Request to Security Service to authenticate user request.
            auth_data = Base.url_encode64(JSON.encode!(%{token: request_data["auth_token"], username: request_data["username"]}))
            {:ok, auth_response} = HTTPoison.post "#{Application.get_env(:directory_service, DirectoryService.Endpoint)[:security_service_host]}/authenticate", 
                                                    "{\"data\": \"" <> auth_data <> "\"}", [{"Content-Type", "application/json"}]
            decrypted_auth_response = decrypt_request(String.trim(auth_response.body, "\""))

            cond do
              Map.has_key?(decrypted_auth_response, "result") and decrypted_auth_response["result"] ->
                
                user_ownership_query = from f in FileData,
                                       where: f.id == ^(request_data["file_id"]) and f.owner_id == ^(decrypted_auth_response["user_id"]),
                                       select: f
                user_ownership = Repo.one(user_ownership_query)

                if user_ownership do
                  # Request to Security Service to get the user_id from the username.
                  user_data = Base.url_encode64(JSON.encode!(%{username: request_data["share_username"]}))
                  {:ok, user_response} = HTTPoison.post "#{Application.get_env(:directory_service, DirectoryService.Endpoint)[:security_service_host]}/uid", 
                                                          "{\"data\": \"" <> user_data <> "\"}", [{"Content-Type", "application/json"}]

                  decrypted_user_response = decrypt_request(String.trim(user_response.body, "\""))

                  cond do
                    Map.has_key?(decrypted_user_response, "result") and decrypted_user_response["result"] ->
                      # Add the file details to the server.
                      changeset = FileData.changeset(%FileData{}, %{uid: decrypted_user_response["user_id"], 
                                                                      owner_id: decrypted_auth_response["user_id"],
                                                                        owner_name: decrypted_auth_response["username"],
                                                                          filename: user_ownership.filename, 
                                                                            server: 0})

                      # Insert new user file in the directory.
                      case Repo.insert(changeset) do
                        {:ok, user_file} ->
                          render conn, "success.json", message: "File successfully shared with " <> request_data["share_username"]
                        {:error, changeset} ->
                          render conn, "failure.json", message: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
                      end
                    Map.has_key?(decrypted_user_response, "result") and !decrypted_user_response["result"] ->
                      render conn, "failure.json", message: decrypted_user_response["message"]
                    true ->
                      render conn, "failure.json", message: "Missing parameters."
                  end
                else
                  render conn, "failure.json", message: "Invalid Ownership."
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

  # Allows a Server to register itself for use with this Directory Service.
  def register_file_server(conn, user_params) do
    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])

        cond do
          Map.has_key?(request_data, "secret_code") and request_data["secret_code"] == "secret_register_password" and Map.has_key?(request_data, "server") ->
            changeset = Server.changeset(%Server{}, %{host: request_data["server"],
                                                        file_count: 0,
                                                          backup: -1})
            case Repo.insert(changeset) do
              {:ok, server_data} ->
                render conn, "success.json", server_id: server_data.id
              {:error, changeset} ->
                render conn, "failure.json", message: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
            end
          true ->
            render conn, "failure.json", message: "Invalid Parameters."
        end
      true ->
        render conn, "failure.json", message: "Missing Parameters."
    end
  end

  # Checks that there is at least one file server registered to this service.
  def has_file_servers() do
    query = from(s in Server, select: count(s.id))
    server_count = List.first(Repo.all(query))
    server_count > 0
  end

  # Gets the file server with the least number of files stored on it.
  def get_file_server() do
    file_server = from s in Server,
                  order_by: s.file_count
    List.first(Repo.all(file_server))
  end

  # Decrypts a base 64 string and converts it into a map
  def decrypt_request(request) do
    JSON.decode!(Base.url_decode64!(request))
  end
end
