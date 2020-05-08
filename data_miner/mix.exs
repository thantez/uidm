defmodule DataMiner.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_miner,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: DataMiner],
      deps: deps(),

      # Docs
      name: "Data Miner",
      source_url: "https://gitlab.com/thantez/uidm/-/tree/master/data_miner",
      homepage_url: "https://gitlab.com/thantez/uidm",
      docs: [
        extras: ["README.md"]
      ]

    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:flow, "~> 1.0"},
      {:logger_file_backend, "~> 0.0.11"},
      {:ex_doc, "~> 0.21.3", only: :dev, runtime: false}
    ]
  end
end
