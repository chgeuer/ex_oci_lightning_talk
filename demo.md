# OCI Lightning Talk

[source](https://tinyurl.com/oci20190129)

```bash
cd /mnt/c/github/chgeuer/ex_oci_lightning_talk

/mnt/c/Program\ Files\ \(x86\)/Elixir/bin/iex -S mix
```

## Elixir

```elixir
#
# Elixir - What's this |> about?
#
# function(a,b,c)        ==       a |> function(b,c)
#

10 - 2

Kernel.-(10, 2)

10 |> Kernel.-(2)

# 10 - 2 - 4
10 |> Kernel.-(2) |> Kernel.-(4)

Kernel.-(Kernel.-(10, 2), 4)
```

## Storage demo

```elixir
#
# Sign in to Storage using Azure AD
#
alias Microsoft.Azure.ActiveDirectory.DeviceAuthenticator
alias Microsoft.Azure.ActiveDirectory.DeviceAuthenticator.Model.State
alias Microsoft.Azure.Storage
alias Microsoft.Azure.Storage.{Container, Blob, Queue, BlobStorage}

storage_account_name = "SAMPLE_STORAGE_ACCOUNT_NAME" |> System.get_env()
storage_account_name = "erlang"
resource = "https://#{storage_account_name}.blob.core.windows.net/"

Fiddler.enable()

{:ok, storage_pid} = DeviceAuthenticator.start(%State{ resource: resource, tenant_id: "chgeuerfte.onmicrosoft.com", azure_environment: :azure_global })

storage_pid |> Process.alive?()
storage_pid |> Process.info()
storage_pid |> :sys.get_state()

#
# Instruct process to trigger authN
#
storage_pid |> DeviceAuthenticator.get_device_code()

#
# Helper function to getch the token
#
aad_token_provider = fn (_resource) ->
    storage_pid |> DeviceAuthenticator.get_token()
    |> elem(1)
    |> Map.get(:access_token)
end

#
# Inspect token contents
#
aad_token_provider.(resource) |> JOSE.JWT.peek() |> Map.get(:fields) |> Map.get("email")
aad_token_provider.(resource) |> JOSE.JWT.peek() |> Map.get(:fields) |> Map.get("aud")

#
# Storage context
#
storage = %Storage{
    cloud_environment_suffix: "core.windows.net",
    account_name: storage_account_name,
    aad_token_provider: aad_token_provider
}

storage = %Storage{
    cloud_environment_suffix: "core.windows.net",
    account_name: "SAMPLE_STORAGE_ACCOUNT_NAME" |> System.get_env(),
    account_key: "SAMPLE_STORAGE_ACCOUNT_KEY" |> System.get_env()
}

storage |> Container.list_containers() |> elem(1) |> Map.get(:containers) |> Enum.map(&Map.get(&1,:name))

container_name = "ocirocks2"

#
# Storage context
#
container = storage |> Container.new(container_name)

container |> Container.create_container()
container |> Container.set_container_acl_public_access_container()

file = "/mnt/c/Users/chgeuer/Videos/Microsoft fun/Bill Gates as Austin Powers-fI_xuFA18m4.mp4"

container |> Blob.upload_file(file)

container |> Container.list_blobs() |>
    elem(1) |>
    Map.get(:blobs) |>
    Enum.map(&(
        {
            &1.name,
            &1.properties.content_length
        }
    ))
```

## SAS

```elixir


Microsoft.Azure.Storage.SharedAccessSignature.sas1() |> Microsoft.Azure.Storage.SharedAccessSignature.sign(System.get_env("SAMPLE_STORAGE_ACCOUNT_KEY"))

```
