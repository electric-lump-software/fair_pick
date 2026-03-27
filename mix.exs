defmodule FairPick.MixProject do
  use Mix.Project

  def project do
    [
      app: :fair_pick,
      version: "0.2.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_file: {:no_warn, "priv/plts/project.plt"}],
      description: "Deterministic, verifiable draw algorithm for provably fair random selection.",
      source_url: "https://github.com/electric-lump-software/fair_pick",
      package: package(),
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/electric-lump-software/fair_pick"}
    ]
  end
end
