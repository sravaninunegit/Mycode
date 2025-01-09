using System.IdentityModel.Tokens.Jwt;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;

namespace vaultex.view.order.domain.order.Services.Okta
{
	public interface IJwtValidator
	{
		string? Issuer { get; set; }
		Task<JwtSecurityToken> TokenValidationExecute(string token, CancellationToken ct);
		TokenValidationParameters GetValidationParameters(OpenIdConnectConfiguration discoveryDocument);
		ConfigurationManager<OpenIdConnectConfiguration> ResolveConfigurationmanager();
	}
}
