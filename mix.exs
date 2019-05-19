defmodule LogisticMap.MixProject do
  use Mix.Project

  def project do
    [
      app: :logistic_map,
      version: "1.1.2",
      elixir: "~> 1.6",
      description: "Benchmark of Logistic Map using integer calculation and `Flow`.",
      package: [
        maintainers: ["Susumu Yamazaki"],
        licenses: ["Apache 2.0"],
        links: %{"GitHub" => "https://github.com/zeam-vm/logistic_map"}
      ],
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:flow, "~> 0.14.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:asm, "~> 0.0.7"}
    ]
  end
end
