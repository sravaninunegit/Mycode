using vaultex.view.order.domain.order.Entities.Okta;

namespace vaultex.view.order.domain.order.Services.Okta
{
	public class OktaJwtValidationService : IOktaJwtValidationService
	{
		public string? _issuer { get; set; }
		public IJwtValidator _jwtValidator { get;}

		public OktaJwtValidationService(IJwtValidator jwtValidator)
		{
			_jwtValidator = jwtValidator;
			_issuer = jwtValidator.Issuer;
		}

		public async Task<OktaResponse> ValidateToken(string token, CancellationToken ct = default)
		{
			try
			{
				if (string.IsNullOrEmpty(token))
				{
					throw new ArgumentNullException(nameof(token));
				}

				if (string.IsNullOrEmpty(_issuer))
				{
					throw new ArgumentNullException(nameof(_issuer));
				}

				var validatedToken = await _jwtValidator.TokenValidationExecute(token, ct);
				return new OktaResponse(true, null, validatedToken);
			}
			catch (Exception ex)
			{
				return new OktaResponse(false, ex);
			}
		}
	}
}
