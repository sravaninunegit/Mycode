using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using vaultex.view.order.domain.order.Entities.Database;

namespace vaultex.view.order.domain.order.Services.Database
{
	public class DatabaseContext : DbContext
	{
		public DatabaseContext(DbContextOptions<DatabaseContext> options)
			: base(options)
		{ }

		public virtual DbSet<DBOrder> WebOrder { get; set; }
		public virtual DbSet<DBOrderMediaSpec> OrderMediaSpec { get; set; }
		public virtual DbSet<DBStagingOrder> StagingOrder { get; set; }
		public virtual async Task ExecuteAddRangeAsync<T>(DbSet<T> set, List<T> values) where T: class=> await set.AddRangeAsync(values);
		public virtual IDbContextTransaction BeginTransaction => Database.BeginTransaction();
	}
}
