defmodule RegistryService.RegistryController do
  use RegistryService.Web, :controller
  alias RegistryService.Service
  alias Poison, as: JSON
  import RegistryService.ErrorHelpers

  # Registers a new service.
  def register(conn, user_params) do 
    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])

        cond do 
          Map.has_key?(request_data, "service") and Map.has_key?(request_data, "hostname") ->
            changeset = Service.changeset(%Service{}, %{name: request_data["service"], hostname: request_data["hostname"]})

            # Insert new user object.
            case Repo.insert_or_update(changeset) do
              {:ok, service} ->
                render conn, "success.json", service: service.name, hostname: service.hostname
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

  # Gets a service hostname give it's name.
  def get_service(conn, user_params) do
    cond do
      Map.has_key?(user_params, "data") ->
        request_data = decrypt_request(user_params["data"])

        cond do 
          Map.has_key?(request_data, "service") ->
            service = Repo.get_by(Service, name: request_data["service"])
            cond do
              service ->
                render conn, "success.json", service: service.name, hostname: service.hostname   
              true ->
                render conn, "failure.json", message: "Service does not exist."
            end
          true ->
            render conn, "failure.json", message: "Missing Parameters."
        end
      true ->
        render conn, "failure.json", message: "Missing Parameters."
    end
  end

  # Decrypts a base 64 string and converts it into a map
  def decrypt_request(request) do
    JSON.decode!(Base.url_decode64!(request))
  end
end
