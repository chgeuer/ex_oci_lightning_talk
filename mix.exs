defmodule ExOciLightningTalk.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_oci_lightning_talk,
      version: "0.1.0",
      elixir: "~> 1.8",
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
      # { :ex_microsoft_azure_storage, github: "chgeuer/ex_microsoft_azure_storage" },
      {:ex_microsoft_azure_storage, path: "../ex_microsoft_azure_storage"},
      # { :ex_microsoft_azure_utils, github: "chgeuer/ex_microsoft_azure_utils" },
      {:ex_microsoft_azure_utils, path: "../ex_microsoft_azure_utils"},
      {:ex_microsoft_azure_management_compute,
       path: "../ex_microsoft_azure_management/Microsoft.Azure.Management.Compute"},
      {:ex_microsoft_azure_management_resources,
       path: "../ex_microsoft_azure_management/Microsoft.Azure.Management.Resources"},
      {:ex_microsoft_azure_management_subscription,
       path: "../ex_microsoft_azure_management/Microsoft.Azure.Management.Subscription"},
      {:ex_microsoft_azure_management_storage,
       path: "../ex_microsoft_azure_management/Microsoft.Azure.Management.Storage"}
    ]
  end
end
