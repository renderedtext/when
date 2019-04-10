defmodule When.ListParser do
  @moduledoc """
  asfa
  """

  @spec parse(binary) :: list
  def parse(str) do
    {:ok, tokens, _} = str |> to_charlist() |> :list_lexer.string()
    {:ok, list} = :list_parser.parse(tokens)
    list
  end
end
