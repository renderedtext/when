defmodule When.CLI do
  def main(args) do
    case args do
      ["list-inputs", "--input", input, "--output", output] ->
        list_inputs(input, output)

      ["reduce", "--input", input, "--output", output] ->
        reduce(input, output)
    end
  end

  def list_inputs(input_path, output_path) do
    result =
      File.read!(input_path)
      |> Poison.decode!()
      |> Enum.map(fn exp -> When.inputs(exp) end)
      |> Poison.encode!()

    File.write!(output_path, result)
  end

  def reduce(input_path, output_path) do
    result =
      File.read!(input_path)
      |> Poison.decode!()
      |> Enum.map(fn e -> When.reduce(e.expression, e.inputs) end)
      |> Poison.encode!()

    File.write!(output_path, result)
  end
end
