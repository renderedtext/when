defmodule When.Interpreter do
  @moduledoc """
  Module takes expression in abstract syntax tree from, replaces all keywords
  with actual values from given params map, and evaluates expression in order to
  return boolean value for when condition which given expression represents.
  """

  @keywords ~w(branch tag pull_request result result_reason)

  def evaluate(string, params, opts \\ []) do
    case evaluate_(string, params, opts) do
      bool when is_boolean(bool)
        -> bool
      int when is_integer(int) and int >= 0
        -> true
      int when is_integer(int) and int < 0
        -> false
      float when is_float(float) and float >= 0.0
        -> true
      float when is_float(float) and float < 0.0
        -> false
      str when is_binary(str) and str != "false"
        -> true
      list when is_list(list) and length(list) == 0
        -> false
      list when is_list(list) and length(list) > 0
        -> true
      error -> error
    end
  end

  defp evaluate_(error = {:error, _}, _params, _opts), do: error

  defp evaluate_({:keyword, keyword}, params, _opts) when keyword in @keywords do
    error_404 = {:error, "Missing value of keyword parameter '#{keyword}'."}
    Map.get(params, keyword, error_404)
  end

  defp evaluate_("false", _params, _opts), do: false
  defp evaluate_("true", _params, _opts), do: true

  defp evaluate_(boolean, _params, _opts) when is_boolean(boolean), do: boolean
  defp evaluate_(string, _params, _opts) when is_binary(string), do: string
  defp evaluate_(integer, _params, _opts) when is_integer(integer), do: integer
  defp evaluate_(float, _params, _opts) when is_float(float), do: float
  defp evaluate_(list, _params, _opts) when is_list(list), do: list

  defp evaluate_({:fun, name, f_params}, params, opts) do
    f_params
    |> Enum.reduce_while([], fn f_param, acc ->
      case evaluate_(f_param, params, opts) do
        {:error, e} -> {:halt, {:error, e}}
        value -> {:cont, acc ++ [value]}
      end
    end)
    |> evaluate_fun(name, params, opts)
  end

  defp evaluate_({"and", first, second}, params, opts) do
    l_value = evaluate_(first, params, opts)
    r_value = evaluate_(second, params, opts)
    apply_opp(l_value, r_value, __MODULE__, :and_func)
  end

  defp evaluate_({"or", first, second}, params, opts) do
    l_value = evaluate_(first, params, opts)
    r_value = evaluate_(second, params, opts)
    apply_opp(l_value, r_value, __MODULE__, :or_func)
  end

  defp evaluate_({"=", first, second}, params, opts) do
    l_value = evaluate_(first, params, opts)
    r_value = evaluate_(second, params, opts)
    apply_opp(l_value, r_value, Kernel, :"==")
  end

  defp evaluate_({"!=", first, second}, params, opts) do
    l_value = evaluate_(first, params, opts)
    r_value = evaluate_(second, params, opts)
    apply_opp(l_value, r_value, Kernel, :"!=")
  end

  defp evaluate_({"=~", first, second}, params, opts) do
    l_value = evaluate_(first, params, opts)
    r_value = evaluate_(second, params, opts)
    apply_opp(~r/#{r_value}/, l_value, Regex, :match?)
  end

  defp evaluate_({"!~", first, second}, params, opts) do
    l_value = evaluate_(first, params, opts)
    r_value = evaluate_(second, params, opts)
    apply_opp(~r/#{r_value}/, l_value, __MODULE__, :not_match?)
  end

  defp evaluate_(error_value, _params, _opts) do
    {:error, "Unsupported value found while interpreting expression: '#{to_str(error_value)}'"}
  end

  defp evaluate_fun(f_params, name, params, opts) do
    not_found_error = "Function with name '#{name}' is not found."
    :when
    |> Application.get_env(name, {:error, not_found_error})
    |> evaluate_fun_({f_params, name, params}, opts)
  end

  defp evaluate_fun_(error = {:error, _msg}, _fun_p, _opts), do: error
  defp evaluate_fun_({module, fun, cardinality}, {f_params, name, params}, opts) do
    if length(f_params) == cardinality do
      call_function(module, fun, f_params ++ [params], opts)
    else
      {:error, "Function '#{name}' accepts #{cardinality} parameter(s)"
                <> " and was provided with #{length(f_params)}."}
    end
  end

  defp call_function(_mod, _fun, _f_params, [dry_run: true]), do: {:ok, false}
  defp call_function(module, fun, f_params, _opts) do
    case apply(module, fun, f_params) do
      {:ok, value} -> value
      {:error, e} -> {:error, "Function '#{fun}' returned error: #{to_str(e)}"}
      error -> {:error, "Function '#{fun}' returned unsupported value: #{to_str(error)}"}
    end
  end

  # Utility

  defp apply_opp(error = {:error, _msg}, _r_value, _module, _func), do: error
  defp apply_opp(_l_value, error = {:error, _msg}, _module, _func), do: error
  defp apply_opp(_pattern, "", _module, :match?), do: false
  defp apply_opp(_pattern, "", _module, :not_match?), do: true
  defp apply_opp(l_value, r_value, module, func) do
    apply(module, func, [l_value, r_value])
  end

  # Helper matching function

  def not_match?(pattern, string), do: not Regex.match?(pattern, string)

  ## This is required because both Kernel.and and Kernel.or are macros, so they can
  ## not be called directly from apply/3
  def and_func(first, second), do: first and second
  def or_func(first, second), do: first or second

  defp to_str(val) when is_binary(val), do: val
  defp to_str(val), do: "#{inspect val}"
end
