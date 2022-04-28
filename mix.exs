defmodule When.MixProject do
  use Mix.Project

  def project do
    [
      app: :when,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:poison, "~> 5.0"}
    ]
  end
end
