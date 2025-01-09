using vaultex.view.order.domain.order.Entities.Database;
using vaultex.view.order.domain.order.Entities.OrderModel;

namespace vaultex.view.order.domain.order.Services.Database
{
	public interface IDatabaseService
	{
		public Task<DatabaseServiceResponse> ExecuteTransactionAsync(List<Order> orders);
	}
}
