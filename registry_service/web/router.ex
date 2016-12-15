defmodule RegistryService.Router do
  use RegistryService.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RegistryService do
    pipe_through :api

    post "/register", RegistryController, :register
    post "/service", RegistryController, :get_service
  end
end
