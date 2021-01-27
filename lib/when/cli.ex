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
      |> Enum.map(fn exp -> list_inputs(exp) end)
      |> Poison.encode!()

    File.write!(output_path, result)
  end

  def reduce(input_path, output_path) do
    result =
      File.read!(input_path)
      |> Poison.decode!()
      |> Enum.map(fn e -> reduce_one_expression(e["expression"], e["inputs"]) end)
      |> Poison.encode!()

    File.write!(output_path, result)
  end

  defp list_inputs(expression) do
    case When.inputs(expression) do
      {:ok, inputs} ->
        %{"inputs" => inputs, "error" => ""}

      {:error, msg} ->
        %{"inputs" => [], "error" => String.replace_prefix(msg, "Syntax error on line 1. - ", "")}
    end
  end

  defp reduce_one_expression(expression, inputs) do
    case When.reduce(expression, inputs) do
      {:ok, result} ->
        %{"result" => result, "error" => ""}

      {:error, error} ->
        %{"result" => "", "error" => error}
    end
  end
end
