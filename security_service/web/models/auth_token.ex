defmodule SecurityService.AuthToken do
  use SecurityService.Web, :model

  schema "auth_tokens" do
    field :token, :string
    field :valid, :boolean
    belongs_to :user, SecurityService.User

    timestamps
  end

  @required_fields ~w(token valid)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end

