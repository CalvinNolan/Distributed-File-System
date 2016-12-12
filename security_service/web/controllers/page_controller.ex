defmodule SecurityService.PageController do
  use SecurityService.Web, :controller

  def index(conn, _params) do
    render conn, "index.json", secret: "sauce"
  end
end
