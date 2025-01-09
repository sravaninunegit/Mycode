using Microsoft.EntityFrameworkCore.Storage;
using vaultex.view.order.domain.order.Entities.Database;
using vaultex.view.order.domain.order.Entities.OrderModel;
using vaultex.view.order.domain.order.Services.OrderMapper;

namespace vaultex.view.order.domain.order.Services.Database
{
	public class DatabaseContextService : IDatabaseContextService
	{
		public IOrderMapper _orderMapper { get; set; }
		public DatabaseContext _databaseContext { get; set; }

		public DatabaseContextService(IOrderMapper orderMapper, DatabaseContext databaseContext)
		{
			_orderMapper = orderMapper;
			_databaseContext = databaseContext;
		}

		public IDbContextTransaction BeginTransaction() => _databaseContext.BeginTransaction;
		public void Commit(IDbContextTransaction transaction) => transaction.Commit();

		public async Task<DatabaseContextServiceResponse> InsertOrders(List<Order> orders)
		{
			var newOrders = _orderMapper.MapObjectsToDatabase(orders);
			await _databaseContext.ExecuteAddRangeAsync(_databaseContext.WebOrder, newOrders);
			await _databaseContext.SaveChangesAsync();

			var dbmMediaSpecs = new List<DBOrderMediaSpec>();
			for (var x = 0; x < orders.Count; x++)
			{
				foreach (OrderMediaSpec spec in orders[x].OrderMediaSpecs)
				{
					var tmpSpec = _orderMapper.MapObjectsToDatabase(spec);
					tmpSpec.WebOrderId = newOrders[x].WebOrderId;
					dbmMediaSpecs.Add(tmpSpec);
				}
			}

			await _databaseContext.ExecuteAddRangeAsync(_databaseContext.OrderMediaSpec, dbmMediaSpecs);
			await _databaseContext.SaveChangesAsync();
			return new DatabaseContextServiceResponse()
			{
				DbOrders = newOrders,
				DBOrderMediaSpecs = dbmMediaSpecs,
			};
		}
	}
}
