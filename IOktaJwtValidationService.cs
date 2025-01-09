using vaultex.view.order.domain.order.Entities.Okta;

namespace vaultex.view.order.domain.order.Services.Okta
{
	public interface IOktaJwtValidationService
	{
		string _issuer { get; set; }
		IJwtValidator _jwtValidator { get; }
		Task<OktaResponse> ValidateToken(string token, CancellationToken ct = default);
	}
}
