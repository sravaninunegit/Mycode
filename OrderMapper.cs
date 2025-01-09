using AutoMapper;
using vaultex.view.order.domain.order.Entities.Database;
using vaultex.view.order.domain.order.Entities.OrderModel;

namespace vaultex.view.order.domain.order.Services.OrderMapper
{
	public class OrderMapper : IOrderMapper
	{ 
		public List<DBOrder> MapObjectsToDatabase(List<Order> orders)
		{
			var mapper = InitializeAutomapper();
			return mapper.Map<List<DBOrder>>(orders);
		}

		public DBOrderMediaSpec MapObjectsToDatabase(OrderMediaSpec order)
		{
			var mapper = InitializeAutomapper();
			return mapper.Map<DBOrderMediaSpec>(order);
		}

		public Mapper InitializeAutomapper()
		{
			var mapper = new Mapper(MapperConfig.GetConfig());
			return mapper;
		}
	}
}
