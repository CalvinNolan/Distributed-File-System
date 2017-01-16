defmodule LockService.Router do
  use LockService.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LockService do
    pipe_through :api 

    post "/lock", LockController, :get_lock
    post "/unlock", LockController, :release_lock

    post "/list", LockController, :list_locks
    post "/isvalid", LockController, :auth_lock_token
    post "/status", LockController, :file_status
  end

  # Other scopes may use custom stacks.
  # scope "/api", LockService do
  #   pipe_through :api
  # end
end
