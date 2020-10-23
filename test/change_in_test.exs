defmodule When.ChangeInTest do
  use ExUnit.Case

  test "evaluate change_in" do
    When.evaluate_change_in("branch = 'test' and change_in('lib/**/*.ex', {})")

    When.evaluate_change_in(
      "branch = 'test' and change_in('test/lib/**/a.ex') or (pull_request = 'test' and change_in('lib/**/*.ex', {}))"
    )
  end
end
