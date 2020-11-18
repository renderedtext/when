defmodule When.CLI do
  def main(args \\ []) do
    case args do
      ["list-inputs", expression] ->
        list_inputs(expression)

      ["reduce", expression, "--input", path] ->
        reduce(expression, path)
    end
  end

  def list_inputs(expression) do
    expression
    |> When.inputs()
    |> Poison.encode!()
    |> IO.puts()
  end

  def reduce(expression, inputs_file_path) do
    {:ok, inputs} = load_json_file(inputs_file_path)
    inputs = When.Reducer.Inputs.from_map(inputs)

    reduced_expression = When.reduce(expression, inputs)

    IO.puts(reduced_expression)
  end

  defp load_json_file(path) do
    {:ok, body} = File.read(path)
    {:ok, json} = Poison.decode(body)
  end
end
