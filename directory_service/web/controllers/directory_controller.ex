defmodule DirectoryService.DirectoryController do
  use DirectoryService.Web, :controller
  alias DirectoryService.File, as: FileData
  alias DirectoryService.Server
  alias DirectoryService.Replication
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
                                    where: f.id == ^(request_data["file_id"]) and f.uid == ^(decrypted_auth_response["user_id"]),
                                    select: f
                user_access = Repo.one(user_access_query)

                if user_access do
                  server_data_query = from s in Server,
                                      where: s.id == ^(user_access.server)
                  server_data = Repo.one(server_data_query)

                  if server_data do
                    # Read the file from the desired server.
                    read_data = Base.url_encode64(JSON.encode!(%{file_id: user_access.file_id}))
                    read_response = HTTPoison.post(server_data.host <> "/read", 
                                                            "{\"data\": \"" <> read_data <> "\"}", 
                                                              [{"Content-Type", "application/json"}])
                    case read_response do
                      {:ok, read_response_data} ->
                        # Send the file contents back to the client.
                        Plug.Conn.send_resp(conn, 200, read_response_data.body)
                      {:error, read_response_error} ->
                        if read_response_error.reason === :econnrefused do
                          invalidate_lost_file_server(server_data)
                          # Read the file from the backup file server.

                          backup_server_query = from s in Server,
                                                where: s.id == ^(server_data.backup)
                          backup_server_data = Repo.one(backup_server_query)
                          read_data = Base.url_encode64(JSON.encode!(%{file_id: user_access.backup_file_id}))
                          read_backup_response = HTTPoison.post(backup_server_data.host <> "/read", 
                                                                  "{\"data\": \"" <> read_data <> "\"}", 
                                                                    [{"Content-Type", "application/json"}])
                          case read_backup_response do
                            {:ok, read_backup_response_data} ->
                              # Send the file contents back to the client.
                              Plug.Conn.send_resp(conn, 200, read_backup_response_data.body)
                            {:error, _} ->
                              render conn, "failure.json", message: "Internal File Server Error."
                          end
                          render conn, "failure.json", message: "Internal File Server Error."
                        else
                          render conn, "failure.json", message: "Internal File Server Error."
                        end
                    end
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

                # Now replicate the file to it's backup server.
                backup_write_response = 
                  case file_server.backup do
                    -1 ->
                      %{:result => true, :message => "No backup server.", :file_id => -1}
                    _ ->
                      backup_server_query = from s in Server,
                                            where: s.id == ^(file_server.backup),
                                            select: s
                      backup_server = Repo.one(backup_server_query)
                      {:ok, backup_write_response} = HTTPoison.post(backup_server.host <> "/write", {:multipart, [{:file, user_params["file_data"].path, 
                                                                      { ["form-data"], [name: "\"file\"", 
                                                                                          filename: new_filename]},
                                                                                            [{"Content-Type", user_params["file_data"].content_type}]}]})
                      decrypt_request(String.trim(backup_write_response.body, "\""))
                  end
                if write_response["result"] and backup_write_response["result"] do
                  # Add the file details to the directory.
                  changeset = FileData.changeset(%FileData{}, %{uid: decrypted_auth_response["user_id"], 
                                                                  owner_id: decrypted_auth_response["user_id"],
                                                                    owner_name: decrypted_auth_response["username"],
                                                                      filename: user_params["file_data"].filename, 
                                                                        file_id: write_response["file_id"],
                                                                          backup_file_id: backup_write_response["file_id"],
                                                                            server: file_server.id})
                  # Insert new user file in the directory.
                  case Repo.insert(changeset) do
                    {:ok, _} ->
                      file_server = Ecto.Changeset.change file_server, file_count: (file_server.file_count + 1)
                      case Repo.update(file_server) do
                        {:ok, _} ->
                          render conn, "success.json", message: "File Successfully Written"
                        {:error, changeset} ->
                          render conn, "failure.json", message: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
                      end
                    {:error, changeset} ->
                      render conn, "failure.json", message: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
                  end
                else
                  if write_response["result"] do
                    render conn, "failure.json", message: backup_write_response["message"]
                  else
                    render conn, "failure.json", message: write_response["message"]
                  end
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
                                       where: f.id == ^(request_data["file_id"]) and f.owner_id == ^(decrypted_auth_response["user_id"])
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
                      changeset = FileData.changeset(%FileData{}, %{uid: decrypted_auth_response["user_id"], 
                                                                      owner_id: decrypted_auth_response["user_id"],
                                                                        owner_name: decrypted_auth_response["username"],
                                                                          filename: user_ownership.filename,  
                                                                            file_id: user_ownership.file_id,
                                                                              backup_file_id: user_ownership.backup_file_id,
                                                                                server: user_ownership.server})
                      # Insert new user file in the directory.
                      case Repo.insert(changeset) do
                        {:ok, _} ->
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
        backup_server = get_replication_file_server

        cond do
          Map.has_key?(request_data, "secret_code") and request_data["secret_code"] == "secret_register_password" and Map.has_key?(request_data, "server") ->
            changeset = Server.changeset(%Server{}, %{host: request_data["server"],
                                                        file_count: 0,
                                                          backup: backup_server.id})
            case Repo.insert(changeset) do
              {:ok, server_data} ->
                # Update the backup file server's backup if it is the only current file server.
                if backup_server.backup == -1 do
                  backup_server = Ecto.Changeset.change backup_server, backup: server_data.id
                  case Repo.update(backup_server) do
                    {:ok, updated_backup_server} ->
                      replicate_onto_backup(updated_backup_server)
                      render conn, "success.json", server_id: server_data.id
                    {:error, changeset} ->
                      render conn, "failure.json", message: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
                  end
                else 
                  render conn, "success.json", server_id: server_data.id
                end
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

  # Gets the most available file server for replicating and backing
  # up another file server.
  def get_replication_file_server() do
    query = from(s in Server, select: count(s.id))
    server_count = List.first(Repo.all(query))

    cond do
      server_count == 1 ->
        single_query = from(s in Server, select: s)
        Repo.one(single_query)
      server_count > 1 ->
        many_query = from(s in Server, order_by: s.file_count, select: s)
        List.first(Repo.all(many_query))
      true ->
        %{id: -1, backup: 0}
    end
  end

  # Gets the most available file server for replicating and backing
  # up another file server that is not the given server_id.
  def get_replication_file_server(server_id) do
    query = from(s in Server, select: count(s.id))
    server_count = List.first(Repo.all(query))

    cond do
      server_count > 1 ->
        many_query = from(s in Server, order_by: s.file_count, where: s.id != ^(server_id), select: s)
        List.first(Repo.all(many_query))
      true ->
        %{id: -1, backup: 0}
    end
  end

  # When a second file system is registered, backup the contents 
  # of the first onto the second.
  def replicate_onto_backup(server) do
    backup_files_query = from f in FileData,
                         where: f.server == ^(server.id)
    backup_files = Repo.all(backup_files_query)
    for file <- backup_files do
      replicate_file = Replication.changeset(%Replication{}, %{file_id: file.id, server_id: server.backup})
      Repo.insert(replicate_file)
    end
  end

  # Invalidate and prepare the data stored for a lost file server
  # for the re-replication process worker that occurs on repeat
  # automatically.
  def invalidate_lost_file_server(file_server) do
    IO.puts "Invalidating file server: " <> to_string(file_server.id) <> " : " <> file_server.host
    IO.puts "Backup: " <> to_string(file_server.backup)

    query = from(s in Server, select: count(s.id))
    server_count = List.first(Repo.all(query))
    if server_count > 2 do
      # First replicate all the files from the dead file server onto a new backup.
      invalid_server_id = file_server.id
      invalid_file_count = file_server.file_count
      new_backup_server = Repo.get_by(Server, id: file_server.backup);
      Repo.delete(file_server)

      # Get all the invalid files from the dead file server.
      invalidate_files_query = from f in FileData,
                               where: f.server == ^(invalid_server_id)
      invalid_files = Repo.all(invalidate_files_query)
      for file <- invalid_files do
        # Add each invalid file for replication to it's new backup.
        replicate_file = Replication.changeset(%Replication{}, %{file_id: file.id, server_id: new_backup_server.backup})
        Repo.insert(replicate_file)

        # Update each file's server to be it's backup
        Repo.update(Ecto.Changeset.change file, server: new_backup_server.id, file_id: file.backup_file_id, backup_file_id: -1)
      end

      # Add file count of dead file server to the backup server which will now host it's files.
      Repo.update(Ecto.Changeset.change new_backup_server, file_count: new_backup_server.file_count + file_server.file_count)

      # Secondly re-backup any file servers that were depending on the newly
      # dead file server.
      backup_servers_query = from s in Server,
                             where: s.backup == ^(invalid_server_id)
      unbackedup_servers = Repo.all(backup_servers_query)

      for server <- unbackedup_servers do
        # Send each of the files in these servers to be replicated in a new file server.
        server_files_query = from f in FileData,
                             where: f.server == ^(server.id)
        server_files = Repo.all(server_files_query)

        new_backup = get_replication_file_server(server.id)
        for server_file <- server_files do
          # Add each invalid file for replication to it's new backup.
          replicate_file = Replication.changeset(%Replication{}, %{file_id: server_file.id, server_id: new_backup.id})
          Repo.insert(replicate_file)
        end
        # Update each file's server to be it's backup
        Repo.update(Ecto.Changeset.change server, backup: new_backup.id)
      end
    else
      if server_count == 2 do
        invalid_server_id = file_server.id
        new_backup_server = Repo.get_by(Server, id: file_server.backup);
        Repo.delete(file_server)

        # Get all the invalid files from the dead file server.
        invalidate_files_query = from f in FileData,
                                 where: f.server == ^(invalid_server_id)
        invalid_files = Repo.all(invalidate_files_query)
        for file <- invalid_files do
          # Update each file's server to be it's backup
          Repo.update(Ecto.Changeset.change file, server: new_backup_server.id)
        end
        Repo.update(Ecto.Changeset.change new_backup_server, backup: -1)
        IO.puts("Not enough registered file servers to replicate.")
      else
        IO.puts("No registered file servers.")
      end
    end
  end

  # Decrypts a base 64 string and converts it into a map
  def decrypt_request(request) do
    JSON.decode!(Base.url_decode64!(request))
  end
end
