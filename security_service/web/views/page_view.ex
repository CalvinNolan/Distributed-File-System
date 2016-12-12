defmodule SecurityService.PageView do
  use SecurityService.Web, :view

  def render("index.json", %{secret: "sauce"}) do
    %{
      secret: "sauce"
    }
  end
end
