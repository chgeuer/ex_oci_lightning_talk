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
# a |> function(b,c) == function(a,b,c)
#
10 - 2
Kernel.-(10, 2)
10 |> Kernel.-(2)

# 10 - 2 - 4
10 |> Kernel.-(2) |> Kernel.-(1)
```
## Storage demo

```elixir
#
# Sign in to Storage using Azure AD
#
alias Microsoft.Azure.ActiveDirectory.{DeviceAuthenticator, DeviceAuthenticatorSupervisor}
alias Microsoft.Azure.ActiveDirectory.DeviceAuthenticator.Model.State
alias Microsoft.Azure.Storage
alias Microsoft.Azure.Storage.{Container, Blob, Queue, BlobStorage}

storage_account_name = "erlang"
resource = "https://#{storage_account_name}.blob.core.windows.net/"

{:ok, storage_pid} = %State{ resource: resource, tenant_id: "chgeuerfte.onmicrosoft.com", azure_environment: :azure_global } |> DeviceAuthenticatorSupervisor.start_link()

storage_pid |> DeviceAuthenticator.get_device_code()

aad_token_provider = fn (_resource) ->
    storage_pid |> DeviceAuthenticator.get_token
    |> elem(1)
    |> Map.get(:access_token)
end

aad_token_provider.(resource)

storage_pid |> DeviceAuthenticatorSupervisor.get_agent_state()

storage_pid |> DeviceAuthenticatorSupervisor.get_worker_pid() |> Process.exit(:kill)

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

Fiddler.enable()

{:ok, %{ containers: container }} = storage |> Container.list_containers()
container |> Enum.map(&(&1.name))

storage |> Container.new("videos") |> Container.list_blobs() |> elem(1) |> Map.get(:blobs) |> Enum.map(&(&1.name))

```

## The rest

```elixir
Timex.now() |> Timex.add(Timex.Duration.from_seconds(3600))

#
# Call into Azure
#
api_version = %{ :resource_groups => "2018-02-01", :subscription => "2016-06-01", :storage => "2018-02-01" }

#
# Save some typing with an `alias`
#
alias Microsoft.Azure.ActiveDirectory.DeviceAuthenticator

#
# Ensure REST calls go through local Fiddler for inspection
#
Fiddler.enable()

#
# Create a 'process' which can poll Azure AD tokens
#
{:ok, pid} = "chgeuerfte.onmicrosoft.com" |> DeviceAuthenticator.start_azure_management()
{:ok, pid} = DeviceAuthenticator.start_azure_management()

#
# a `PID` is a 'process ID', i.e. the ID of an actor, running on an Erlang VM
#
pid

#
# Check if it is alive
#
Process.alive?(pid)
pid |> Process.alive?()

#
# Check some process info
#
pid |> Process.info()

#
# This process is waiting for messages to arrive
#
Process.info(pid)[:status]

#
# We can look at it's internal state
#
:sys.get_state(pid)

pid |> DeviceAuthenticator.get_device_code()

pid |> DeviceAuthenticator.get_stage()

# Pattern matching
{ :ok, %{ access_token: token } } = pid |> DeviceAuthenticator.get_token()
# Functional (LINQ-style) navigating through the structure
token = pid |> DeviceAuthenticator.get_token() |> elem(1) |> Map.get(:access_token)

pid |> DeviceAuthenticator.force_refresh()
pid |> DeviceAuthenticator.get_token() |> elem(1) |> Map.get(:access_token) |> JOSE.JWT.peek() |> Map.get(:fields) |> Map.get("iat")

token
token |> JOSE.JWT.peek()
token |> JOSE.JWT.peek() |> Map.get(:fields) |> Enum.map( fn({k,v}) -> "#{k |> String.pad_trailing(12, " ")}: #{inspect(v)}" end) |> Enum.join("\n") |> IO.puts()

#
# Turn on logging
#
props = storage |> BlobStorage.get_blob_service_properties() |> elem(1) |> Map.get(:service_properties)
storage |> BlobStorage.set_blob_service_properties(Map.put(props, :logging, %Logging{ version: "1.0", delete: :true, read: true, write: true, retention_policy: %RetentionPolicy{ days: 30, enabled: true }}))


#
# Create an HttpClient with BearerToken set
#
conn = token |> Microsoft.Azure.Management.Resources.Connection.new()

#
# Fetch list of subscriptions
#
subscription_name = "chgeuer-work"

subscriptions = conn |> Microsoft.Azure.Management.Subscription.Api.Subscriptions.subscriptions_list(api_version.subscription)

subscription_id = subscriptions |>
   elem(1) |>
   Map.get(:value) |>
   Enum.filter(&(&1 |> Map.get(:displayName) == subscription_name)) |>
   hd |>
   Map.get(:subscriptionId)

alias Microsoft.Azure.Management.Storage.Api.StorageAccounts, as: StorageManagement

storage_accounts = conn |> StorageManagement.storage_accounts_list(api_version.storage, subscription_id)

my_preferred_account = "erlang"

storage_account = storage_accounts |> elem(1) |> Map.get(:value) |> Enum.filter(&(&1 |> Map.get(:name) == my_preferred_account)) |> Enum.take(1) |> hd

storage_account_id = storage_account.id

storage_account_id |> String.split("/")

resource_group_name = storage_account_id |> String.split("/") |> Enum.at(4)

[_, "subscriptions", ^subscription_id, "resourceGroups", resource_group_name, "providers", "Microsoft.Storage", "storageAccounts", storage_account_name] = storage_account_id |> String.split("/")


{:ok, %{keys: [ %{value: storage_account_key}, _]}} = conn |> StorageManagement.storage_accounts_list_keys(resource_group_name, storage_account_name, api_version.storage, subscription_id)


alias Microsoft.Azure.Storage
alias Microsoft.Azure.Storage.{Container, Blob, Queue}
storage_account_name = "SAMPLE_STORAGE_ACCOUNT_NAME" |> System.get_env()
storage_account_key = "SAMPLE_STORAGE_ACCOUNT_KEY" |> System.get_env()
storage = %Storage{account_name: storage_account_name, account_key: storage_account_key, cloud_environment_suffix: "core.windows.net" }
storage |> Queue.new("queue1") |> Queue.get_metadata()
storage |> Queue.new("queue1") |> Queue.put_message("Yeah, jjjj")

storage |> Container.new("oci123") |> Container.get_container_acl

#
# List container names
#
storage |> Container.list_containers() |> elem(1) |> Map.get(:containers) |> Enum.map(&(&1.name))

#
# Delete a bunch of containers
#
["oci123", "oci1234", "ocid1"] |> Enum.map(fn(c) -> storage |> Container.new(c) |> Container.delete_container() end)


container_name = "ocid2"

storage |> Container.new(container_name) |> Container.create_container()

storage |> Container.new(container_name) |> Container.set_container_acl_public_access_container()

storage |> Container.new(container_name) |> Blob.upload_file("/mnt/c/Users/chgeuer/Videos/Microsoft fun/Bill Gates as Austin Powers-fI_xuFA18m4.mp4")

storage |> Container.new(container_name) |> Container.list_blobs()

storage |>
   Container.new(container_name) |>
   Container.list_blobs() |>
   elem(1) |>
   Map.get(:blobs) |>
   Enum.map(&(
       {
           &1.name,
           &1.properties.content_length
        }
    ))

System.halt
```
