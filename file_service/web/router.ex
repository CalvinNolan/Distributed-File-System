defmodule FileService.Router do
  use FileService.Web, :router

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

  scope "/", FileService do
    pipe_through :api

    get "/", FileController, :index

    post "/write", FileController, :write_file
    post "/read", FileController, :read_file
  end

  # Other scopes may use custom stacks.
  # scope "/api", FileService do
  #   pipe_through :api
  # end
end
