defmodule WhenTest do
  use ExUnit.Case
  doctest When

  test "greets the world" do
    assert When.hello() == :world
  end
end
