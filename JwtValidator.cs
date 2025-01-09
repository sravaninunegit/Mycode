using System.IdentityModel.Tokens.Jwt;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;

namespace vaultex.view.order.domain.order.Services.Okta
{
	public class JwtValidator : IJwtValidator
	{
		public string? Issuer { get; set; }

		public JwtValidator(string issuer)
		{
			Issuer = issuer;
		}

		public async Task<JwtSecurityToken> TokenValidationExecute(string token, CancellationToken ct)
		{
			var configManager = ResolveConfigurationmanager();
			var discoveryDocument = await configManager.GetConfigurationAsync(ct);

			_ = new JwtSecurityTokenHandler()
				.ValidateToken(token, GetValidationParameters(discoveryDocument), out var rawValidatedToken);

			return (JwtSecurityToken)rawValidatedToken;
		}

		public TokenValidationParameters GetValidationParameters(OpenIdConnectConfiguration discoveryDocument)
		{
			var signingKeys = discoveryDocument.SigningKeys;

			return new TokenValidationParameters
			{
				RequireExpirationTime = true,
				RequireSignedTokens = true,
				ValidateIssuer = true,
				ValidIssuer = Issuer,
				ValidateIssuerSigningKey = true,
				IssuerSigningKeys = signingKeys,
				ValidateLifetime = true,
				ClockSkew = TimeSpan.FromMinutes(2),
				ValidateAudience = false,
			};
		}

		public ConfigurationManager<OpenIdConnectConfiguration> ResolveConfigurationmanager() => new ConfigurationManager<OpenIdConnectConfiguration>(
				Issuer + "/.well-known/oauth-authorization-server",
				new OpenIdConnectConfigurationRetriever(),
				new HttpDocumentRetriever());
	}
}
