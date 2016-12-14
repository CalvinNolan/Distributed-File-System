defmodule SecurityService.AuthView do
  use SecurityService.Web, :view

  def render("logOut.json", %{message: message}) do
    %{
      result: true,
      message: message
    }
  end

  def render("failure.json", %{message: message}) do
  	%{
  		result: false,
  		message: message
  	}
  end

  def render("success.json", %{user: user, token: token}) do
  	%{
  		result: true,
  		user_id: user.id,
  		username: user.username,
      token: token
  	}
  end
end
