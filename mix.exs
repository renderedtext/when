defmodule When.MixProject do
  use Mix.Project

  def project do
    [
      app: :when,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:credo, "~> 0.9", only: [:dev, :test], runtime: false},
      {:poison, "~> 3.1"}
    ]
  end
end
