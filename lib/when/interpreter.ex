defmodule When.Interpreter do
  alias When.Reducer.Inputs

  def evaluate(ast, params, opts \\ []) do
    opts = Keywords.merge([dry_run: false], opts)

    #
    # In the first pass, we are reducing the expression without inputs.
    # This will give us a list of necessary inputs, and also verify the
    # validity of the expression.
    #
    result = When.Reducer.reduce(ast)

    if Keywords.get(opts, :dry_run) == true do
      Result.has_errors?(result)
    else
      case prepare_inputs(result.missing_inputs, params) do
        {:ok, inputs} -> evaluate_or_fail(ast, params)
        {:error, error} -> {:error, error}
      end
    end
  end

  def evaluate_or_fail(ast, inputs) do
    result = When.Reducer.reduce(ast, inputs)

    cond do
      Result.has_errors?(result) ->
        result.errors

      result.missing_inputs != [] ->
        missing_inputs_error(result.missing_inputs)

      true ->
        When.Reducer.Result.to_bool(result)
    end
  end

  def prepare_inputs(missing_inputs, params) do
    prepare_inputs(missing_inputs, params, Inputs.new())
  end

  def prepare_inputs([head | tail] = missing_inputs, params, inputs) do
    case head do
      %{type: :keyword, name: name} ->
        if Map.has_key?(params) do
          prepare_inputs(tail, params, Inputs.add(inputs, :keyword, name, Map.get(name)))
        else
          {:error, "Missing value of keyword parameter '#{name}'."}
        end

      %{type: :fun, name: name, params: fparams} ->
        case apply(:when, name, fparams) do
          {:ok, value} ->
            prepare_inputs(tail, params, Inputs.add(inputs, :fun, name, fparams, value))

          {:error, {err_type, e}} when is_atom(err_type) ->
            {:error, {err_type, "Function '#{name}' returned error: #{inspect(e)}"}}

          {:error, e} ->
            {:error, "Function '#{name}' returned error: #{inspect(e)}"}

          error ->
            {:error, "Function '#{name}' returned unsupported value: #{inspect(error)}"}
        end

      m ->
        {:error, "Expression requires an unknown input format '#{inspect(m)}'."}
    end
  end

  def missing_inputs_error(missing_inputs) do
    %{name: name, type: :keyword} = hd(missing_inputs)

    {:error, "Missing value of keyword parameter '#{name}'."}
  end
end
