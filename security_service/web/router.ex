defmodule SecurityService.Router do
  use SecurityService.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SecurityService do
    pipe_through :api # Use the default browser stack

    get "/", PageController, :index
  end
end
