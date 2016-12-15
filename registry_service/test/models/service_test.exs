defmodule RegistryService.ServiceTest do
  use RegistryService.ModelCase

  alias RegistryService.Service

  @valid_attrs %{hostname: "some content", name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Service.changeset(%Service{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Service.changeset(%Service{}, @invalid_attrs)
    refute changeset.valid?
  end
end
