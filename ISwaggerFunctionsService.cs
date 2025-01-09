using AzureFunctions.Extensions.Swashbuckle;
using AzureFunctions.Extensions.Swashbuckle.Attribute;
using Microsoft.Azure.Functions.Worker;

namespace vaultex.view.order.domain.order.Services.Swagger
{
	public interface ISwaggerFunctionsService
	{
		public Task<HttpResponseMessage> CreateSwaggerJsonDocumentResponse(
		[HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "swagger/json")] HttpRequestMessage req,
		[SwashBuckleClient] ISwashBuckleClient swasBuckleClient);
		public Task<HttpResponseMessage> CreateSwaggerUIResponse(
		[HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "swagger/ui")] HttpRequestMessage req,
		[SwashBuckleClient] ISwashBuckleClient swasBuckleClient);
	}
}
