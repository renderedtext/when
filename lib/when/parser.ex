defmodule When.Parser do
  @moduledoc """
  Uses parser generated by 'yecc' erlang tool based on specification defined in
  "src/when_parser.yrl" to performe syntax analysis on given tokens list and
  form abstract syntax tree which is later used by interpreter to evaluate expression.
  """

  def parse(tokens) do
    case :when_parser.parse(tokens) do
      {:ok, ast} -> {:ok, ast}
      error -> pretty_error(error)
    end
  end

  defp pretty_error(
         {:error, {line_no, :when_parser, ['syntax error before: ', [[_, _, operator, _, _]]]}}
       ) do
    {:error,
     "Syntax error on line #{line_no}. - " <>
       "Invalid expression on the left of '#{rm_qoutes(operator)}' operator."}
  end

  defp pretty_error({:error, {line_no, :when_parser, ['syntax error before: ', []]}}) do
    {:error,
     "Syntax error on line #{line_no}. - " <>
       "Invalid or incomplete expression at the end of the line."}
  end

  defp pretty_error({:error, {line_no, :when_parser, ['syntax error before: ', bracket]}}) do
    {:error,
     "Syntax error on line #{line_no}. - " <>
       "Invalid expression on the left of '#{rm_qoutes(bracket)}'."}
  end

  defp pretty_error({:error, {line_no, :when_parser, error}}) do
    {:error,
     "Syntax error on line #{line_no}. - " <>
       "Unrecongnized error: #{inspect(error)}"}
  end

  defp pretty_error({:error, error}) do
    {:error, "Syntax error - Unrecongnized error: #{inspect(error)}"}
  end

  defp pretty_error(error) do
    {:error, "Syntax error - Unrecongnized error: #{inspect(error)}"}
  end

  defp rm_qoutes(atom) when is_atom(atom) do
    atom |> Atom.to_string() |> rm_qoutes()
  end

  defp rm_qoutes(char_list) when is_list(char_list) do
    char_list |> to_string() |> rm_qoutes()
  end

  defp rm_qoutes(string) when is_binary(string) do
    string |> String.replace(~s("), "") |> String.replace(~s('), "")
  end

  defp rm_qoutes(other), do: other
end
