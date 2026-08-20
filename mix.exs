defmodule Abit.MixProject do
  use Mix.Project

  @version "1.0.0"
  @github "https://github.com/preciz/abit"

  def project do
    [
      app: :abit,
      name: "Abit",
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      homepage_url: @github,
      source_url: @github,
      description: "Use Erlang atomics as a bit array or as an array of N-bit counters."
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:benchee, "~> 1.5", only: :dev},
      {:stream_data, "~> 1.4", only: :test}
    ]
  end

  defp docs do
    [
      main: "Abit",
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      source_ref: "v#{@version}",
      source_url: @github
    ]
  end

  defp package do
    [
      maintainers: ["Barna Kovacs"],
      licenses: ["MIT"],
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md", "LICENSE"],
      links: %{"GitHub" => @github}
    ]
  end
end
