defmodule DirectoryService.ReplicationTest do
  use DirectoryService.ModelCase

  alias DirectoryService.Replication

  @valid_attrs %{file_id: 42, server_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Replication.changeset(%Replication{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Replication.changeset(%Replication{}, @invalid_attrs)
    refute changeset.valid?
  end
end
