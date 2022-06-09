defmodule GoveeScenic.MixProject do
  use Mix.Project

  def project do
    [
      app: :govee_scenic,
      version: "0.1.0",
      elixir: "~> 1.9",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {GoveeScenicApplication, []},
      extra_applications: [:crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:scenic, "~> 0.11.0-beta.0"},
      {:scenic, github: "boydm/scenic", branch: "v0.11", override: true},
      # {:scenic, path: "~/dev/forks/scenic", override: true},
      {:scenic_driver_local, "~> 0.11.0-beta.0"},
      # {:scenic_live_reload, github: "axelson/scenic_live_reload", ref: "wip-v0.11", only: :dev},
      {:scenic_live_reload, path: "~/dev/scenic_live_reload", only: :dev},
    ]
  end
end
