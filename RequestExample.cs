using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Abstractions;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Resolvers;
using Newtonsoft.Json.Serialization;
using vaultex.view.order.domain.order.Entities.OpenAPI;
using vaultex.view.order.domain.order.Entities.OrderModel;

namespace vaultex.view.order.domain.order.Utilities
{
	public class RequestExample : OpenApiExample<List<Order>>
    {
        public override IOpenApiExample<List<Order>> Build(NamingStrategy namingStrategy = null)
        {
            Examples.Add(
                OpenApiExampleResolver.Resolve(
                    ResourceDictionary.OrdersExample,
                    new List<Order>()
                    {
						ExampleOrderValue.Value
                    },
                    namingStrategy
                ));

            return this;
        }
    }
}
