defmodule LockService.LockController do
  use LockService.Web, :controller
  alias Poison, as: JSON
  alias LockService.Lock
  import Ecto.Query, only: [from: 2]

  # Generate a lock for a given file and assign
  # it to a user which will lock the file.
  def get_lock(conn, user_params) do
    conn = conn 
        |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:lock_service, LockService.Endpoint)[:client_service_host])
        |> put_resp_header("Access-Control-Allow-Credentials", "true")
        |> fetch_session()

    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])

        cond do
          Map.has_key?(request_data, "username") and Map.has_key?(request_data, "auth_token") and Map.has_key?(request_data, "file_id") ->
            # Request to Security Service to authenticate user request.
            auth_data = Base.url_encode64(JSON.encode!(%{token: request_data["auth_token"], username: request_data["username"]}))
            {:ok, auth_response} = HTTPoison.post "#{Application.get_env(:lock_service, LockService.Endpoint)[:security_service_host]}/authenticate", 
                                                    "{\"data\": \"" <> auth_data <> "\"}", [{"Content-Type", "application/json"}]
            decrypted_auth_response = decrypt_request(String.trim(auth_response.body, "\""))

            cond do
              Map.has_key?(decrypted_auth_response, "result") and decrypted_auth_response["result"] ->
                # Request to Security Service to authenticate user request.
                file_auth_data = Base.url_encode64(JSON.encode!(%{user_id: decrypted_auth_response["user_id"], file_id: request_data["file_id"]}))
                {:ok, file_auth_response} = HTTPoison.post "#{Application.get_env(:lock_service, LockService.Endpoint)[:directory_service_host]}/access", 
                                                        "{\"data\": \"" <> file_auth_data <> "\"}", [{"Content-Type", "application/json"}]
                decrypted_file_auth_response = decrypt_request(String.trim(file_auth_response.body, "\""))

                if Repo.get_by(Lock, file_id: decrypted_file_auth_response["file_id"]) do
                  render conn, "failure.json", message: "Already locked by another user."
                else
                  if Map.has_key?(decrypted_file_auth_response, "result") and decrypted_file_auth_response["result"] and decrypted_file_auth_response["has_access"] do
                    # Generate token
                    lock_token = :crypto.strong_rand_bytes(64) |> Base.url_encode64 |> binary_part(0, 64)
                    changeset = Lock.changeset(%Lock{}, %{file_id: decrypted_file_auth_response["file_id"], 
                                                            directory_file_id: request_data["file_id"],
                                                              lock_token: lock_token, 
                                                                owner_id: decrypted_auth_response["user_id"]})
                    case Repo.insert(changeset) do
                      {:ok, _} ->
                        user_locks = from l in Lock,
                                     where: l.owner_id == ^(decrypted_auth_response["user_id"])
                        render conn, "success.json", locks: Repo.all(user_locks)
                      {:error, _} ->
                        render conn, "failure.json", message: "Unable to attain lock."
                    end
                  else
                    render conn, "failure.json", message: "Unauthorized."
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

  # Release a user's lock for a given file
  def release_lock(conn, user_params) do
    conn = conn 
        |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:lock_service, LockService.Endpoint)[:client_service_host])
        |> put_resp_header("Access-Control-Allow-Credentials", "true")
        |> fetch_session()

    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])

        cond do
          Map.has_key?(request_data, "username") and Map.has_key?(request_data, "auth_token") and Map.has_key?(request_data, "file_id") ->
            # Request to Security Service to authenticate user request.
            auth_data = Base.url_encode64(JSON.encode!(%{token: request_data["auth_token"], username: request_data["username"]}))
            {:ok, auth_response} = HTTPoison.post "#{Application.get_env(:lock_service, LockService.Endpoint)[:security_service_host]}/authenticate", 
                                                    "{\"data\": \"" <> auth_data <> "\"}", [{"Content-Type", "application/json"}]
            decrypted_auth_response = decrypt_request(String.trim(auth_response.body, "\""))

            cond do
              Map.has_key?(decrypted_auth_response, "result") and decrypted_auth_response["result"] ->


                # Request to Security Service to authenticate user request.
                file_auth_data = Base.url_encode64(JSON.encode!(%{user_id: decrypted_auth_response["user_id"], file_id: request_data["file_id"]}))
                {:ok, file_auth_response} = HTTPoison.post "#{Application.get_env(:lock_service, LockService.Endpoint)[:directory_service_host]}/access", 
                                                        "{\"data\": \"" <> file_auth_data <> "\"}", [{"Content-Type", "application/json"}]
                decrypted_file_auth_response = decrypt_request(String.trim(file_auth_response.body, "\""))

                if Map.has_key?(decrypted_file_auth_response, "result") and decrypted_file_auth_response["result"] and decrypted_file_auth_response["has_access"] do
                  # If the locks owner is this user, delete it.
                  lock = Repo.get_by(Lock, file_id: decrypted_file_auth_response["file_id"])
                  if lock && lock.owner_id == decrypted_auth_response["user_id"] do
                    Repo.delete(lock)
                    user_locks = from l in Lock,
                                 where: l.owner_id == ^(decrypted_auth_response["user_id"])
                    render conn, "success.json", locks: Repo.all(user_locks)
                  else
                    render conn, "failure.json", message: "No lock to release."
                  end
                else
                  render conn, "failure.json", message: "Unauthorized."
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

  # Gives a list of all the locks a user owns.
  def list_locks(conn, user_params) do
    conn = conn 
        |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:lock_service, LockService.Endpoint)[:directory_service_host])
        |> put_resp_header("Access-Control-Allow-Credentials", "true")
        |> fetch_session()

    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])

        cond do
          Map.has_key?(request_data, "user_id") ->
            lock_query = from l in Lock,
                         where: l.owner_id == ^(request_data["user_id"]),
                         select: %{"directory_file_id" => l.directory_file_id, "lock_token" => l.lock_token}
            locks = Repo.all(lock_query)
            render conn, "success.json", locks: locks
          true ->
            render conn, "failure.json", message: "Missing parameters."
        end
      true ->
        render conn, "failure.json", message: "Missing parameters."
    end
  end

  # Accessible only for the Directory service
  # Authenticates a lock token for a given file id.
  def auth_lock_token(conn, user_params) do
    conn = conn 
        |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:lock_service, LockService.Endpoint)[:directory_service_host])
        |> put_resp_header("Access-Control-Allow-Credentials", "true")
        |> fetch_session()

    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])

        cond do
          Map.has_key?(request_data, "file_id") && Map.has_key?(request_data, "lock_token") ->
            lock_query = from l in Lock,
                         where: l.file_id == ^(request_data["file_id"])
            lock = Repo.one(lock_query)
            if lock do
              render conn, "success.json", is_token: request_data["lock_token"] == lock.lock_token
            else
              render conn, "success.json", is_token: true
            end
          true ->
            render conn, "failure.json", message: "Missing parameters."
        end
      true ->
        render conn, "failure.json", message: "Missing parameters."
    end
  end

  # Accessible only for the Directory service
  # Gives the lock status of a file given it's id.
  def file_status(conn, user_params) do
    conn = conn 
        |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:lock_service, LockService.Endpoint)[:directory_service_host])
        |> put_resp_header("Access-Control-Allow-Credentials", "true")
        |> fetch_session()

    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])
        cond do
          Map.has_key?(request_data, "file_id") ->
            if Repo.get_by(Lock, directory_file_id: request_data["file_id"]) do
              render conn, "success.json", is_locked: true
            else
              render conn, "success.json", is_locked: false
            end
          true ->
            render conn, "failure.json", message: "Missing parameters."
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
