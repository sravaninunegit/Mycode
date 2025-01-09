using AzureFunctions.Extensions.Swashbuckle;
using AzureFunctions.Extensions.Swashbuckle.Attribute;
using Microsoft.Azure.Functions.Worker;

namespace vaultex.view.order.domain.order.Services.Swagger
{
	public class SwaggerFunctionsService : ISwaggerFunctionsService
	{
		public Task<HttpResponseMessage> CreateSwaggerJsonDocumentResponse(
			[HttpTrigger(AuthorizationLevel.Anonymous, new[] { "get" }, Route = "swagger/json")]
			HttpRequestMessage req,
			[SwashBuckleClient] ISwashBuckleClient swasBuckleClient) => Task.FromResult(swasBuckleClient.CreateSwaggerJsonDocumentResponse(req));

		public Task<HttpResponseMessage> CreateSwaggerUIResponse(
			[HttpTrigger(AuthorizationLevel.Anonymous, new[] { "get" }, Route = "swagger/ui")]
			HttpRequestMessage req,
			[SwashBuckleClient] ISwashBuckleClient swasBuckleClient) =>  Task.FromResult(swasBuckleClient.CreateSwaggerUIResponse(req, "swagger/json"));
	}
}
