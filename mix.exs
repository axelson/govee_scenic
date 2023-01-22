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
      {:phoenix_pubsub, "~> 2.1"},
      {:typed_struct, "~> 0.2"},
      # {:govee, path: "~/dev/govee"},
      {:govee, github: "axelson/govee", branch: "new-update"},
      {:scenic, "~> 0.11"},
      # {:scenic, path: "~/dev/forks/scenic", override: true},
      {:scenic_driver_local, "~> 0.11"},
      # {:scenic_live_reload, github: "axelson/scenic_live_reload", ref: "wip-v0.11", only: :dev},
      {:scenic_live_reload, path: "~/dev/scenic_live_reload", only: :dev},
    ]
  end
end
