defmodule When.CLI do
  def main(args) do
    case args do
      ["hello"] ->
        IO.puts("hello")

      ["list-inputs", "--input", input, "--output", output] ->
        list_inputs(input, output)

      ["reduce", expression, "--input", path] ->
        reduce(expression, path)
    end
  end

  def list_inputs(input_path, output_path) do
    result =
      File.read!(input_path)
      |> Poison.decode!()
      |> Enum.map(fn line -> When.inputs(line) end)
      |> Poison.encode!()

    File.write!(output_path, result)
  end

  def reduce(expression, inputs_file_path) do
    {:ok, inputs} = load_json_file(inputs_file_path)
    inputs = When.Reducer.Inputs.from_map(inputs)

    reduced_expression = When.reduce(expression, inputs)

    IO.puts(reduced_expression)
  end

  defp load_json_file(path) do
    {:ok, body} = File.read(path)

    Poison.decode(body)
  end
end
