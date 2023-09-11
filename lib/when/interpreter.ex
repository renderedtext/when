defmodule When.Interpreter do
  @moduledoc """
  Module takes expression in abstract syntax tree form, replaces keywords
  with actual values from given input map, and evaluates expression using reducer
  in order to return boolean value for when condition which given expression represents.
  """

  alias When.Reducer.Inputs

  def evaluate(ast, params, opts \\ []) do
    opts = Keyword.merge([dry_run: false], opts)

    #
    # In the first pass, we are reducing the expression without inputs.
    # This will give us a list of necessary inputs, and also verify the
    # validity of the expression.
    #
    result = When.Reducer.reduce(ast)

    case prepare_inputs(result.missing_inputs, params, opts) do
      {:ok, inputs} -> evaluate_or_fail(ast, inputs)
      {:error, error} -> {:error, error}
    end
  end

  def evaluate_or_fail(ast, inputs) do
    result = When.Reducer.reduce(ast, inputs)

    cond do
      When.Reducer.Result.has_errors?(result) ->
        result.errors

      result.missing_inputs != [] ->
        missing_inputs_error(result.missing_inputs)

      true ->
        When.Reducer.Result.to_bool(result)
    end
  end

  def prepare_inputs(missing_inputs, params, opts) do
    prepare_inputs(missing_inputs, params, Inputs.new(), opts)
  end

  def prepare_inputs([], _params, inputs, _opts), do: {:ok, inputs}

  def prepare_inputs([head | tail], params, inputs, opts) do
    case head do
      %{type: :keyword, name: name} ->
        if Map.has_key?(params, name) do
          inputs = Inputs.add(inputs, :keyword, name, Map.get(params, name))
          prepare_inputs(tail, params, inputs, opts)
        else
          {:error, "Missing value of keyword parameter '#{name}'."}
        end

      %{type: :fun, name: name, params: f_params} ->
        case evaluate_fun(f_params, name, params, opts) do
          {:ok, value} ->
            inputs = Inputs.add(inputs, :fun, Atom.to_string(name), f_params, value)
            prepare_inputs(tail, params, inputs, opts)

          error ->
            error
        end

      m ->
        {:error, "Expression requires an unknown input format '#{inspect(m)}'."}
    end
  end

  defp evaluate_fun(f_params, name, params, opts) do
    not_found_error = "Function with name '#{name}' is not found."

    :when
    |> Application.get_env(name, {:error, not_found_error})
    |> evaluate_fun_({f_params, name, params}, opts)
  end

  defp evaluate_fun_(error = {:error, _msg}, _fun_p, _opts), do: error

  defp evaluate_fun_({module, fun, cardinalities}, {f_params, name, params}, opts) do
    if length(f_params) in cardinalities do
      call_function(module, fun, f_params ++ [params], opts)
    else
      {:error,
       "Function '#{name}' accepts #{to_str(cardinalities)} parameter(s)" <>
         " and was provided with #{length(f_params)}."}
    end
  end

  defp call_function(_mod, _fun, _f_params, dry_run: true), do: {:ok, false}

  defp call_function(module, fun, f_params, _opts) do
    case apply(module, fun, f_params) do
      {:ok, value} ->
        {:ok, value}

      {:error, {err_type, e}} when is_atom(err_type) ->
        {:error, {err_type, "Function '#{fun}' returned error: #{to_str(e)}"}}

      {:error, e} ->
        {:error, "Function '#{fun}' returned error: #{to_str(e)}"}

      error ->
        {:error, "Function '#{fun}' returned unsupported value: #{to_str(error)}"}
    end
  end

  def missing_inputs_error(missing_inputs) do
    %{name: name, type: :keyword} = hd(missing_inputs)

    {:error, "Missing value of keyword parameter '#{name}'."}
  end

  # Utility

  defp to_str(val) when is_binary(val), do: val

  defp to_str([elem | list]) when is_integer(elem) and is_list(list) and length(list) >= 2 do
    "#{elem}, #{to_str(list)}"
  end

  defp to_str(list) when is_list(list) and length(list) == 2,
    do: "#{Enum.at(list, 0)} or #{Enum.at(list, 1)}"

  defp to_str(list) when is_list(list) and length(list) == 1, do: "#{Enum.at(list, 0)}"
  defp to_str(val), do: "#{inspect(val)}"
end
