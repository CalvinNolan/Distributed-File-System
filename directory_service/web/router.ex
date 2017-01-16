defmodule DirectoryService.Router do
  use DirectoryService.Web, :router

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

  scope "/", DirectoryService do
    pipe_through :api
    
    post "/write", DirectoryController, :write_file
    post "/read", DirectoryController, :read_file
    post "/update", DirectoryController, :update_file
    post "/all", DirectoryController, :list_files

    post "/share", DirectoryController, :share_file
    post "/register", DirectoryController, :register_file_server
    post "/access", DirectoryController, :has_access
  end
end
