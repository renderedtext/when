defmodule When.MixProject do
  use Mix.Project

  def project do
    [
      app: :when,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:yecc, :leex] ++ Mix.compilers(),
      escript: escript()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:junit_formatter, "~> 3.1", only: [:test]},
      {:poison, "~> 4.0"}
    ]
  end

  defp escript do
    [main_module: When.CLI]
  end
end
