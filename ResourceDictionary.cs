namespace vaultex.view.order.domain.order.Utilities
{
	public static class ResourceDictionary
	{
		public static readonly string UnauthorizedEmptyHeaders = "Error - error while getting headers";
		public static readonly string UnauthorizedNullRequest = "Error - null request";
		public static readonly string BadRequestMessageJSON = "Incorrect JSON format: ";
		public static readonly string BadRequestMessageNullBody = "Request body was null or empty";
		public static readonly string SuccessMessage = "Records successfully received and passed:";
		public static readonly string DatabaseErrorMessage = "Passing data to database failed with following error: ";
		public static readonly string OktaErrorMessage = "Failure while authorizing: ";

		public static readonly string OrdersExample = "OrdersExample";
		public static readonly string OrdersFunction = "OrdersFunction";
		public static readonly string AuthorizationHeaderValue = "Authorization";
		public static readonly string RequestBody = "RequestBody";
	}
}
