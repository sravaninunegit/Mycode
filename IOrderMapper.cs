using AutoMapper;
using vaultex.view.order.domain.order.Entities.Database;
using vaultex.view.order.domain.order.Entities.OrderModel;

namespace vaultex.view.order.domain.order.Services.OrderMapper
{
	public interface IOrderMapper
	{
		List<DBOrder> MapObjectsToDatabase(List<Order> orders);
		DBOrderMediaSpec MapObjectsToDatabase(OrderMediaSpec order);
		Mapper InitializeAutomapper();
	}
}
