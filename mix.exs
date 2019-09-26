defmodule Abit.MixProject do
  use Mix.Project

  @version "0.1.1"
  @github "https://github.com/preciz/abit"

  def project do
    [
      app: :abit,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      homepage_url: @github,
      description: """
      Helper functions to use :atomics as a bit array in Elixir.
      """
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @github,
    ]
  end

  defp package do
    [
      maintainers: ["Barna Kovacs"],
      licenses: ["MIT"],
      links: %{github: @github},
      files: ~w(LICENSE.md README.md mix.exs)
    ]
  end
end
