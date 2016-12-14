defmodule SecurityService.User do
  use SecurityService.Web, :model

  schema "users" do
    field :username, :string
    field :password, :string

    has_many :auth_tokens, SecurityService.AuthToken

    timestamps
  end

  @required_fields ~w(username password)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:username)
    |> validate_length(:username, min: 3)
    |> validate_length(:username, max: 20)
    |> validate_length(:password, min: 6)
    |> validate_length(:password, max: 254)
  end
end