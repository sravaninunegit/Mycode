using AzureFunctions.Extensions.Swashbuckle;
using AzureFunctions.Extensions.Swashbuckle.Attribute;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.WebJobs;

namespace vaultex.view.order.domain.order.Services.Swagger
{
	public class SwaggerFunctions
	{
		ISwaggerFunctionsService _swaggerFunctionsService;
		public	SwaggerFunctions(ISwaggerFunctionsService swaggerFunctionsService)
		{
			_swaggerFunctionsService = swaggerFunctionsService;
		}

		[SwaggerIgnore]
		[FunctionName("Swagger")]
		public  Task<HttpResponseMessage> Swagger(
		[Microsoft.Azure.Functions.Worker.HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "swagger/json")] HttpRequestMessage req,
		[SwashBuckleClient] ISwashBuckleClient swasBuckleClient) => _swaggerFunctionsService.CreateSwaggerJsonDocumentResponse(req, swasBuckleClient);

		[SwaggerIgnore]
		[FunctionName("SwaggerUI")]
		public  Task<HttpResponseMessage> SwaggerUI(
		[Microsoft.Azure.Functions.Worker.HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "swagger/ui")] HttpRequestMessage req,
		[SwashBuckleClient] ISwashBuckleClient swasBuckleClient) => _swaggerFunctionsService.CreateSwaggerUIResponse(req, swasBuckleClient);
	}
}
