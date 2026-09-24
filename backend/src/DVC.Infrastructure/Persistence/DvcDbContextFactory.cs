using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace DVC.Infrastructure.Persistence
{
    public class DvcDbContextFactory : IDesignTimeDbContextFactory<DvcDbContext>
    {
        public DvcDbContext CreateDbContext(string[] args)
        {
            var connectionString =
                Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");

            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new InvalidOperationException(
                    "ConnectionStrings__DefaultConnection environment variable is not configured.");
            }

            var optionsBuilder = new DbContextOptionsBuilder<DvcDbContext>();

            optionsBuilder.UseNpgsql(connectionString);

            return new DvcDbContext(optionsBuilder.Options);
        }
    }
}