using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Newtonsoft.Json.Linq;

internal class Program
{
    /// <param name="credentialsFile">A .NET SDK credentials file</param>
    /// <param name="rg">The name of the resource group containing the Container App environment</param>
    /// <param name="env">The name of the Container App environment</param>
    private static async Task Main(string credentialsFile, string rg, string env)
    {
        var azure = await Azure
            .Configure()
            .Authenticate(SdkContext.AzureCredentialsFactory.FromFile(credentialsFile))
            .WithDefaultSubscriptionAsync();

        var appEnv = await azure.GenericResources.GetAsync(rg, "Microsoft.Web", null, "kubeenvironments", env);

        var apps = await (await azure.GenericResources.ListByResourceGroupAsync(rg))
            .Where(r => r.Type == "Microsoft.Web/containerApps")
            .ToAsyncEnumerable()
            .SelectAwait(async r => await azure.GenericResources.GetByIdAsync(r.Id))
            .Where(r => ((JObject)r.Properties).Value<string>("kubeEnvironmentId") == appEnv.Id)
            .ToListAsync();

        // TODO: Map the app definitions to Kubernetes YAML
    }
}