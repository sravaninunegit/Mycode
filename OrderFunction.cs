using System.Net;
using System.Text.Json;
using System.Web.Http;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Enums;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi.Models;
using vaultex.view.order.domain.order.Entities.Database;
using vaultex.view.order.domain.order.Entities.OrderModel;
using vaultex.view.order.domain.order.Services.Database;
using vaultex.view.order.domain.order.Services.Okta;
using vaultex.view.order.domain.order.Utilities;

namespace vaultex.view.order.domain.order
{
	public class OrderFunction
	{
		private IOktaJwtValidationService _jwtValidator;
		private IDatabaseService _databaseService;
		private static TelemetryClient telemetryClient =new TelemetryClient();

		public bool isTest;
		public string? authToken;
		private readonly ILogger<OrderFunction> _logger;
		private List<Order> orders;

		public IDatabaseService DatabaseService
		{
			get => _databaseService;
			set => _databaseService = value;
		}

		public IOktaJwtValidationService JwtValidator
		{
			get => _jwtValidator;
			set => _jwtValidator = value;
		}

		public OrderFunction(ILoggerFactory loggerFactory, IOktaJwtValidationService jwtValidator, IDatabaseService databaseService)
		{
			_jwtValidator = jwtValidator;
			_logger = loggerFactory.CreateLogger<OrderFunction>();
			_databaseService = databaseService;
		}

		[Function("order-domain/order")]
		[OpenApiOperation(operationId: "Run", tags: new[] { "name" })]
		[OpenApiSecurity("function_key", SecuritySchemeType.ApiKey, Name = "code", In = OpenApiSecurityLocationType.Query)]
		[OpenApiRequestBody(contentType: "application/json", bodyType: typeof(List<Order>), Description = "Sample Orders List", Required = true)]
		[OpenApiResponseWithBody(statusCode: HttpStatusCode.OK, contentType: "text/plain", bodyType: typeof(string), Description = "The OK response")]
		[OpenApiResponseWithBody(statusCode: HttpStatusCode.Unauthorized, contentType: "text/plain", bodyType: typeof(string), Description = "The Unauthorized response")]
		public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequestData req)
		{
			try
			{				

				var headerValues = req.Headers.GetValues(ResourceDictionary.AuthorizationHeaderValue);
				authToken = headerValues.FirstOrDefault();
			}
			catch
			{
				if (!isTest)
				{
					_logger.LogError(ResourceDictionary.UnauthorizedEmptyHeaders);
					return new UnauthorizedResult();
				}
			}

			if (string.IsNullOrEmpty(authToken))
			{
				_logger.LogError(ResourceDictionary.UnauthorizedNullRequest);
				return new UnauthorizedResult();
			}

			var oktaResponse = await _jwtValidator.ValidateToken(authToken);
			if (oktaResponse?.ValidatedToken is null || !oktaResponse.IsSuccess)
			{
				_logger.LogError($"{ResourceDictionary.OktaErrorMessage}{oktaResponse?.Ex}");
				return new BadRequestErrorMessageResult($"{ResourceDictionary.OktaErrorMessage}{oktaResponse?.Ex}");
			}

			if (req is null || req.Body?.Length == 0 || req.Body is null)
			{
				_logger.LogError(ResourceDictionary.BadRequestMessageNullBody);
				return new BadRequestErrorMessageResult(ResourceDictionary.BadRequestMessageNullBody);
			}

			try
			{
				var tmp = JsonSerializer.Deserialize<List<Order>>(req.Body);

				if (tmp is not null && tmp.Count > 0)
				{
					orders = tmp;					
					#region added for issue from appinsight to get payload for the request					
					telemetryClient.TrackTrace(ResourceDictionary.OrdersFunction+ JsonSerializer.Serialize(orders), SeverityLevel.Information);
					#endregion
				}
				else
					throw new JsonException();
			}
			catch (Exception ex)
			{
				_logger.LogError($"{ResourceDictionary.BadRequestMessageJSON}{ex}");
				return new BadRequestErrorMessageResult($"{ResourceDictionary.BadRequestMessageJSON}{ex}");
			}

			var res = new DatabaseServiceResponse(false);
			var processedCount = 0;
			try
			{
				#region added for validation
				var list=ValidatorUtils.ValidateOrder(orders);
				if (list!=null && list.Count>0)
				{
					telemetryClient.TrackTrace(ResourceDictionary.OrdersFunction + JsonSerializer.Serialize(list), SeverityLevel.Information);
					return new BadRequestObjectResult(list);
				}
				#endregion				
				var tempRes = await _databaseService.ExecuteTransactionAsync(orders);
				res.IsSuccess = tempRes.IsSuccess;
				res.Ex = tempRes.Ex;
				processedCount = orders.Count;
			}
			catch (Exception ex)
			{
				res.IsSuccess = false;
				res.Ex = ex;
			}

			if (res.IsSuccess)
			{
				_logger.LogInformation($"{ResourceDictionary.SuccessMessage}{processedCount}");
				return new OkObjectResult($"{ResourceDictionary.SuccessMessage}{processedCount}");
			}
			else
			{
				_logger.LogError($"{ResourceDictionary.DatabaseErrorMessage}{res.Ex}");
				return new BadRequestErrorMessageResult($"{ResourceDictionary.DatabaseErrorMessage}{res.Ex}");
			}
		}
	}
}
