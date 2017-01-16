defmodule LockService.LockTest do
  use LockService.ModelCase

  alias LockService.Lock

  @valid_attrs %{file_id: 42, lock_token: "some content", owner_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Lock.changeset(%Lock{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Lock.changeset(%Lock{}, @invalid_attrs)
    refute changeset.valid?
  end
end
