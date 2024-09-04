defmodule When.CLITest do
  use ExUnit.Case

  describe "list-inputs" do
    def list(test_file) do
      When.CLI.main(["list-inputs", "--input", test_file, "--output", "/tmp/output.json"])

      output = File.read!("/tmp/output.json")

      Poison.decode!(output)
    end

    test "it produces a list of necessary inputs for each when expression" do
      test_file = "test/files/inputs/valid.json"

      result = list(test_file)

      assert result == [
               %{
                 "inputs" => [%{"name" => "branch", "type" => "keyword"}],
                 "error" => ""
               },
               %{
                 "inputs" => [%{"name" => "change_in", "params" => ["/lib"], "type" => "fun"}],
                 "error" => ""
               }
             ]
    end

    test "if the expressions is invalid" do
      test_file = "test/files/inputs/invalid.json"

      result = list(test_file)

      assert length(result) == 3

      assert Enum.at(result, 0) == %{
               "inputs" => [],
               "error" => "Invalid or incomplete expression at the end of the line."
             }

      assert Enum.at(result, 1) == %{
               "inputs" => [],
               "error" => "Invalid expression on the left of 'true'."
             }

      assert Enum.at(result, 2) == %{
               "inputs" => [],
               "error" => "Invalid expression on the left of 'branch' operator."
             }
    end
  end

  describe "reduce" do
    def reduce(test_file) do
      When.CLI.main(["reduce", "--input", test_file, "--output", "/tmp/output.json"])

      output = File.read!("/tmp/output.json")

      Poison.decode!(output)
    end

    test "it reduces the expressions" do
      test_file = "test/files/inputs/reduce.json"

      result = reduce(test_file)

      assert result == [
               %{"result" => "true", "error" => ""},
               %{"result" => "false", "error" => ""}
             ]
    end

    test "if some inputs are missing" do
      test_file = "test/files/inputs/missing_input.json"

      result = reduce(test_file)

      assert length(result) == 2

      assert Enum.at(result, 0) == %{
               "result" => "branch = 'master'",
               "error" => ""
             }

      assert Enum.at(result, 1) == %{
               "result" => "change_in('/lib')",
               "error" => ""
             }
    end
  end
end
