using AutoMapper;
using vaultex.view.order.domain.order.Entities.Database;
using vaultex.view.order.domain.order.Entities.OrderModel;

namespace vaultex.view.order.domain.order.Services.OrderMapper
{
	public static class MapperConfig
	{
		public static MapperConfiguration GetConfig() => new(cfg =>
		{
			cfg.CreateMap<Order, DBOrder>();
			cfg.CreateMap<OrderMediaSpec, DBOrderMediaSpec>();
		});
	}
}
