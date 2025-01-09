using Microsoft.Azure.Functions.Worker.Extensions.OpenApi.Extensions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using vaultex.view.order.domain.order.Entities.HealthCheck;
using vaultex.view.order.domain.order.Services.Database;
using vaultex.view.order.domain.order.Services.HealthCheck;
using vaultex.view.order.domain.order.Services.Okta;
using vaultex.view.order.domain.order.Services.OrderMapper;
using vaultex.view.order.domain.order.Services.Swagger;

var databaseConnectionString = string.Empty;
var oktaIssuer = string.Empty;

var host = new HostBuilder()
	.ConfigureFunctionsWorkerDefaults()
	.ConfigureAppConfiguration(builder =>
	{
#if DEBUG
		var configuration = builder.SetBasePath(Directory.GetCurrentDirectory())
			.AddJsonFile("appSettings.json", false)
			.AddEnvironmentVariables()
			.Build();

		databaseConnectionString = configuration.GetConnectionString("SqlConnectionString");
		oktaIssuer = configuration.GetConnectionString("OktaIssuer");
#else
		var configuration = builder.Build();

		builder.AddAzureAppConfiguration(options =>
		{
			options.Connect(configuration.GetConnectionString("AzureAppConfigurationConnection"))
				.Select("VaultexView:OrderDomain:*", "VaultexView")
				.ConfigureRefresh(refreshOptions =>
					refreshOptions.Register($"VaultexView:OrderDomain:{VersionConfig.SectionName}", refreshAll: true));
		});

		databaseConnectionString = configuration.GetConnectionString("SqlConnectionString");
	    oktaIssuer = configuration.GetConnectionString("OktaIssuer");
#endif
	})
	.ConfigureOpenApi()
	.ConfigureServices((hostBuilderContext, configureDelegate)=>
	{
		configureDelegate.AddSingleton<IJwtValidator>(new JwtValidator(oktaIssuer));
		configureDelegate.AddTransient<IOktaJwtValidationService, OktaJwtValidationService>();
		configureDelegate.AddTransient<IDatabaseService, DatabaseService>();
		configureDelegate.AddTransient<IDatabaseContextService, DatabaseContextService>();
		configureDelegate.AddTransient<IOrderMapper, OrderMapper>();
		configureDelegate.AddTransient<ISwaggerFunctionsService, SwaggerFunctionsService>();

		configureDelegate.AddDbContext<DatabaseContext>(
			options =>
			SqlServerDbContextOptionsExtensions.UseSqlServer(options, databaseConnectionString));

		configureDelegate.AddScoped<IHealthReportWrapper, HealthReportWrapper>();
		configureDelegate.AddScoped<IHealthReportWrapper, HealthReportWrapper>();

		configureDelegate.AddOptions<VersionConfig>()
			.Configure<IConfiguration>((settings, configuration) => configuration.GetSection($"VaultexView:OrderDomain:{VersionConfig.SectionName}").Bind(settings));

		configureDelegate.AddCustomHealthChecks(hostBuilderContext.Configuration);
	})
	.Build();

host.Run();
