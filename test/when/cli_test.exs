defmodule When.CLITest do
  use ExUnit.Case

  describe "list-inputs" do
    def list(expressions) do
      input = Poison.encode!(expressions)

      File.write("/tmp/input.json", input)
      When.CLI.main(["list-inputs", "--input", "/tmp/input.json", "--output", "/tmp/output.json"])

      output = File.read!("/tmp/output.json")

      Poison.decode!(output)
    end

    test "it produces a list of necessary inputs for each when expression" do
      expressions = [
        "branch = 'master'",
        "change_in('/lib')"
      ]

      result = list(expressions)

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
      expressions = [
        "branch = 'master' and ahahahahaha",
        "branch = true",
        "{branch or false}"
      ]

      result = list(expressions)

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
    def reduce(expressions) do
      input = Poison.encode!(expressions)

      File.write("/tmp/input.json", input)
      When.CLI.main(["reduce", "--input", "/tmp/input.json", "--output", "/tmp/output.json"])

      output = File.read!("/tmp/output.json")

      Poison.decode!(output)
    end

    test "it reduces the expressions" do
      expressions = [
        %{
          "expression" => "branch = 'master'",
          "inputs" => %{
            "keywords" => %{"branch" => "master"},
            "functions" => %{}
          }
        },
        %{
          "expression" => "change_in('/lib')",
          "inputs" => %{
            "keywords" => %{},
            "functions" => [
              %{
                "name" => "change_in",
                "params" => ["/lib"],
                "result" => false
              }
            ]
          }
        }
      ]

      result = reduce(expressions)

      assert result == [
               %{"result" => "true", "error" => ""},
               %{"result" => "false", "error" => ""}
             ]
    end

    test "if some inputs are missing" do
      expressions = [
        %{
          "expression" => "branch = 'master'",
          "inputs" => %{
            "keywords" => %{},
            "functions" => []
          }
        },
        %{
          "expression" => "change_in('/lib')",
          "inputs" => %{
            "keywords" => %{},
            "functions" => []
          }
        }
      ]

      result = reduce(expressions)

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
