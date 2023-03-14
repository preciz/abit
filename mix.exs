defmodule Abit.MixProject do
  use Mix.Project

  @version "0.3.1"
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
      Use `:atomics` as a bit array or as an array of N-bit counters.
      """
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.29.2", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "Abit",
      source_ref: "v#{@version}",
      source_url: @github
    ]
  end

  defp package do
    [
      maintainers: ["Barna Kovacs"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github}
    ]
  end
end
