# Elixir on Azure Demo

```bash
cd /mnt/c/github/chgeuer/ex_oci_lightning_talk

#
# "iex -S mix" is the interactive Elixir shell
#
/mnt/c/Program\ Files\ \(x86\)/Elixir/bin/iex -S mix
```

```elixir
#
# Ensure we can see requests in Fiddler
#
Fiddler.enable()

#
# Save some keystrokes
#
alias Microsoft.Azure.Storage
alias Microsoft.Azure.Storage.{Container, Blob, Queue, BlobStorage}

#
# A data structure which contains connection information for an
# Azure Storage Account (with a storage account key)
#
storage_with_account_key = %Storage{
    cloud_environment_suffix: "core.windows.net",
    account_name: "SAMPLE_STORAGE_ACCOUNT_NAME" |> System.get_env(),
    account_key: "SAMPLE_STORAGE_ACCOUNT_KEY" |> System.get_env()
}

#
# List the containers
#
storage_with_account_key |>
    Container.list_containers() |> elem(1) |>
    Map.get(:containers) |>
    Enum.map(&(&1.name))

container_name = "video"

#
# Just a data structure which refers to a container
#
storage_with_account_key |>
    Container.new(container_name)

#
# Create the container
#
storage_with_account_key |>
    Container.new(container_name) |>
    Container.create_container()

#
# Set downloads for public
#
storage_with_account_key |>
    Container.new(container_name) |>
    Container.set_container_acl_public_access_container()

#
# Sign in to Storage using Azure AD
#
alias Microsoft.Azure.ActiveDirectory.{DeviceAuthenticator, DeviceAuthenticatorSupervisor}
alias Microsoft.Azure.ActiveDirectory.DeviceAuthenticator.Model.State

#
# Use storage from previous sample
#
storage_account_name = System.get_env("SAMPLE_STORAGE_ACCOUNT_NAME")

resource = "https://#{storage_account_name}.blob.core.windows.net/"

#
# Start an Erlang process which can handle device authN
#
{:ok, storage_pid} = %State{
        resource: resource,
        tenant_id: "chgeuerfte.onmicrosoft.com",
        azure_environment: :azure_global
} |>
    DeviceAuthenticatorSupervisor.start_link()

#
# A lambda which can retrieve the access token from
# the supervised Erlang process
#
aad_token_provider = fn (_resource) ->
    storage_pid |> DeviceAuthenticator.get_token
    |> elem(1)
    |> Map.get(:access_token)
end

aad_token_provider.(resource)

#
# Trigger device sign-in flow
#
storage_pid |> DeviceAuthenticator.get_device_code()

#
# Quickly have a look at the token
#
aad_token_provider.(resource) |>
    JOSE.JWT.peek() |>
    Map.get(:fields) |>
    Map.get("email")

aad_token_provider.(resource) |> JOSE.JWT.peek()

#
# Different data structure for storage account,
# this time with a 'hot' AAD connection
#
storage_via_aad = %Storage{
    account_name: storage_account_name,
    cloud_environment_suffix: "core.windows.net",
    aad_token_provider: aad_token_provider
}


local_filename =
    "/mnt/c/Users/chgeuer/Videos/Microsoft fun/Bill Gates as Austin Powers-fI_xuFA18m4.mp4"

#
# Upload some file
#
storage_via_aad |>
    Container.new(container_name) |>
    Blob.upload_file(local_filename)

#
# List the blobs
#
storage_via_aad |>
    Container.new(container_name) |>
    Container.list_blobs() |>
    elem(1) |>
    Map.get(:blobs)
