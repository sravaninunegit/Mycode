using vaultex.view.order.domain.order.Entities.Database;
using vaultex.view.order.domain.order.Entities.OrderModel;

namespace vaultex.view.order.domain.order.Services.Database
{
	public class DatabaseService : IDatabaseService
	{
		public IDatabaseContextService _databaseContextService { get; set; }
		public DatabaseService(IDatabaseContextService databaseContextService)
		{
			_databaseContextService = databaseContextService;
		}

		public async Task<DatabaseServiceResponse> ExecuteTransactionAsync(List<Order> orders)
		{
			using var transaction = _databaseContextService?.BeginTransaction();

			if (transaction == null || _databaseContextService == null)
				return new DatabaseServiceResponse(false);

			try
			{
				_ = await _databaseContextService.InsertOrders(orders);
				_databaseContextService.Commit(transaction);

				return new DatabaseServiceResponse(true);
			}
			catch (Exception ex)
			{
				return new DatabaseServiceResponse(false, ex);
			}
		}
	}
}
