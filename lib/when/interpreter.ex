defmodule When.Interpreter do
  def evaluate(ast, params) do
    result = When.Reducer.reduce(ast, params)

    if result.missing_input == [] do
      When.Reducer.Result.to_bool(result)
    else
      {_, name} = hd(result.missing_input)

      {:error, "Missing value of keyword parameter '#{name}'."}
    end
  end
end
