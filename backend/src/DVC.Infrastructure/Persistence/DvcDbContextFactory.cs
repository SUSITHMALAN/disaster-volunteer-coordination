using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace DVC.Infrastructure.Persistence
{
    public class DvcDbContextFactory : IDesignTimeDbContextFactory<DvcDbContext>
    {
        public DvcDbContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<DvcDbContext>();

            var connectionString = Environment.GetEnvironmentVariable("DVC_DATABASE_CONNECTION");

            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new InvalidOperationException(
                    "DVC_DATABASE_CONNECTION environment variable is not configured.");
            }

            optionsBuilder.UseNpgsql(connectionString);

            return new DvcDbContext(optionsBuilder.Options);
        }
    }
}