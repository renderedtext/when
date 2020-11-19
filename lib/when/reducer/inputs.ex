defmodule When.Reducer.Inputs do
  @moduledoc """
  A structure that provides inputs to the expression reducer.

  Example:

    ast = When.ast("branch = 'development'")
    inputs = Inputs.new() |> Inputs.add(:keyword, branch, "master")

    When.Reducer.reduce(ast, inputs)
    # => false
  """

  def new() do
    %{
      "keywords" => %{},
      "functions" => []
    }
  end

  def from_map(m) do
    %{
      "keywords" => m["keywords"],
      "functions" => m["functions"]
    }
  end

  def add(inputs, :keyword, name, value) do
    keywords = Map.merge(inputs["keywords"], %{name => value})

    %{inputs | "keywords" => keywords}
  end

  def add(inputs, :fun, name, params, result) do
    entry = %{"name" => name, "params" => params, "result" => result}

    %{inputs | "functions" => inputs["functions"] ++ [entry]}
  end

  def get_keyword(inputs, name) do
    Map.get(inputs["keywords"], name)
  end

  def get_function(inputs, name, params) do
    inputs["functions"]
    |> Enum.find(fn el ->
      el["name"] == name && el["params"] == stringify_map(params)
    end)
  end

  defp stringify_map(map) do
    map |> Poison.encode!() |> Poison.decode!()
  end
end
