using Microsoft.EntityFrameworkCore.Storage;
using vaultex.view.order.domain.order.Entities.Database;
using vaultex.view.order.domain.order.Entities.OrderModel;
using vaultex.view.order.domain.order.Services.OrderMapper;

namespace vaultex.view.order.domain.order.Services.Database
{
	public interface IDatabaseContextService
	{
		IOrderMapper _orderMapper { get; set; }
		DatabaseContext _databaseContext { get; set; }

		Task<DatabaseContextServiceResponse> InsertOrders(List<Order> orders);
		IDbContextTransaction BeginTransaction();
		void Commit(IDbContextTransaction transaction);
	}
}
