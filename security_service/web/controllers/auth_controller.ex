defmodule SecurityService.AuthController do
  use SecurityService.Web, :controller
  alias SecurityService.User
  alias SecurityService.AuthToken
  alias Poison, as: JSON
  import Ecto.Query, only: [from: 2]
  import SecurityService.ErrorHelpers

  # Take in a username, password and confirmation 
  # password and create a new user account.
  def create_user(conn, user_params) do
    conn = conn 
            |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:security_service, SecurityService.Endpoint)[:client_service_host])
            |> put_resp_header("Access-Control-Allow-Credentials", "true")
            |> fetch_session()

  	cond do
      conn.cookies["auth_token"] ->
        render conn, "failure.json", message: "Already logged in."

      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])

        cond do 
          Map.has_key?(request_data, "username") and Map.has_key?(request_data, "password") ->
        
            changeset = User.changeset(%User{}, %{username: request_data["username"], password: Comeonin.Bcrypt.hashpwsalt(request_data["password"])})

    		    # Insert new user object.
            case Repo.insert(changeset) do
              {:ok, user} ->
              	auth_token = create_unique_token()

              	# Invalidate all tokens for that user id.
                from(p in AuthToken, join: c in assoc(p, :user), where: c.id == ^(user.id))
                |> Repo.update_all(set: [valid: false])

                # Create and insert new auth token object.
                changeset = Ecto.build_assoc(user, :auth_tokens, %{token: auth_token, valid: true})
    			      case Repo.insert(changeset) do
                  {:ok, token} ->
                    conn
                    |> Plug.Conn.put_resp_cookie("auth_token", auth_token, max_age: 30*365*24*60*60)
                    |> render("success.json", user: user, token: token.token)
                  {:error, changeset} ->
                    render conn, "failure.json", message: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
                end
              {:error, changeset} ->
                render conn, "failure.json", message: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
            end
          true ->
            render conn, "failure.json", message: "Missing parameters."
        end
      true ->
      	render conn, "failure.json", message: "Missing parameters."
  	end
  end

  # Take in a username and password and return a token for that user.
  def log_in(conn, user_params) do
    conn = conn 
            |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:security_service, SecurityService.Endpoint)[:client_service_host])
            |> put_resp_header("Access-Control-Allow-Credentials", "true")
            |> fetch_session()

    cond do
      conn.cookies["auth_token"] ->
        render conn, "failure.json", message: "Already logged in."

      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])

        cond do 
          Map.has_key?(request_data, "username") and Map.has_key?(request_data, "password") ->
            user = Repo.get_by(User, username: String.downcase(request_data["username"]))

            cond do
              user ->
                if Comeonin.Bcrypt.checkpw(request_data["password"], user.password) do
                  auth_token = create_unique_token()

                  # invalidate all tokens for that user id.
                  from(p in AuthToken, join: c in assoc(p, :user), where: c.id == ^(user.id))
                  |> Repo.update_all(set: [valid: false])

                  # insert new token as valid and set it as response cookie.
                  changeset = Ecto.build_assoc(user, :auth_tokens, %{token: auth_token, valid: true})
                  case Repo.insert(changeset) do
                    {:ok, token} ->
                      conn
                      |> Plug.Conn.put_resp_cookie("auth_token", auth_token, max_age: 30*365*24*60*60)
                      |> render("success.json", user: user, token: token.token)
                    {:error, changeset} ->
                      render conn, "failure.json", message: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
                  end
                else
                  render conn, "failure.json", message: "Failed login."
                end       
              true ->
                render conn, "failure.json", message: "Username does not exist."
            end
          true ->
            render conn, "failure.json", message: "Missing Parameters."
        end
      true ->
        render conn, "failure.json", message: "Missing Parameters."
    end
  end

  # Logs a user out of their current session.
  def log_out(conn, _params) do
  	conn
      |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:security_service, SecurityService.Endpoint)[:client_service_host])
      |> put_resp_header("Access-Control-Allow-Credentials", "true")
      |> Plug.Conn.put_resp_cookie("auth_token", "", max_age: 0)
      |> render("logOut.json", message: "Farewell.")
  end

  # Take in a token and username and confirm it is valid.
  def authenticate(conn, user_params) do
    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])

        cond do 
          Map.has_key?(request_data, "username") and Map.has_key?(request_data, "password") ->
            query = from u in User,
                    join: t in assoc(u, :auth_tokens),
                    where: t.token == ^(request_data["token"]) and t.valid == true and u.username == ^(request_data["username"]),
                    select: u
            user = Repo.one(query)
            if user do
              render conn, "success.json", user: user, token: request_data["token"]
            else
              render conn, "failure.json", message: "Failed Auth."
            end
          true ->
            render conn, "failure.json", message: "Missing parameters."
        end
      true ->
        render conn, "failure.json", message: "Missing parameters."
    end
  end

  # Checks a users cookies if they're already logged in.
  def check_auth_status(conn, _user_params) do
    conn = conn 
            |> put_resp_header("Access-Control-Allow-Origin", Application.get_env(:security_service, SecurityService.Endpoint)[:client_service_host])
            |> put_resp_header("Access-Control-Allow-Credentials", "true")
            |> fetch_session()

    if conn.cookies["auth_token"] do
      query = from u in User,
              join: t in assoc(u, :auth_tokens),
              where: t.token == ^(conn.cookies["auth_token"]) and t.valid == true,
              select: u
      user = Repo.one(query)
      if user do
        render conn, "success.json", user: user, token: conn.cookies["auth_token"]
      else
        conn
          |> Plug.Conn.put_resp_cookie("auth_token", "", max_age: 0)
          |> render("failure.json", message: "Invalid token.")
      end 
    else
      render conn, "failure.json", message: "Not logged in."
    end
  end

  # Generates a unique auth token that has never been used before.
  def create_unique_token() do
    auth_token = :crypto.strong_rand_bytes(64) |> Base.url_encode64 |> binary_part(0, 64)

    if Repo.get_by(AuthToken, token: auth_token) do
      create_unique_token()
    else
      auth_token
    end
  end

  # Decrypts a base 64 string and converts it into a map
  def decrypt_request(request) do
    IO.puts request
    JSON.decode!(Base.url_decode64!(request))
  end
end
