defmodule SecurityService.Router do
  use SecurityService.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SecurityService do
    pipe_through :api
    
    post "/signup", AuthController, :create_user
    post "/logout", AuthController, :log_out
    post "/login", AuthController, :log_in
    post "/authenticate", AuthController, :authenticate
    get "/status", AuthController, :check_auth_status

    post "/uid", AuthController, :uid_from_username
  end
end
