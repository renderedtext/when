defmodule When.MixProject do
  use Mix.Project

  def project do
    [
      app: :when,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:poison, "~> 3.1"}]
  end

  defp escript do
    [main_module: When.CLI, emu_args: "-mode minimal +sbtu +A0 -noinput -boot no_dot_erlang"]
  end
end
