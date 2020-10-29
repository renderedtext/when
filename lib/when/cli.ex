defmodule When.CLI do
  def main([command | params]) do
    case command do
      "function-calls" ->
        [input, function_name, output_type] = params

        calls =
          input
          |> When.ast!()
          |> When.AST.function_calls(function_name: String.to_atom(function_name))

        IO.puts("hello")

        if output_type == "bash-params" do
          calls
          |> Enum.map(fn %{name: name, params: params} ->
            "#{name} #{encode_to_bash_paramers(params)}"
          end)
          |> IO.inspect()
        else
          calls |> inspect() |> IO.puts()
        end
    end
  end

  def encode_to_bash_paramers(arr) when is_list(arr) do
    arr |> Enum.map(fn e -> encode_to_bash_paramers(e) end) |> Enum.join(" ")
  end

  def encode_to_bash_paramers(map) when is_map(map) do
    map
    |> Enum.map(fn k, v ->
      "--#{encode_to_bash_paramers(k)}=#{encode_to_bash_paramers(v)}"
    end)
    |> Enum.join(" ")
  end

  def encode_to_bash_paramers(str) when is_binary(str), do: str
  def encode_to_bash_paramers(number) when is_integer(number), do: "#{number}"
end
