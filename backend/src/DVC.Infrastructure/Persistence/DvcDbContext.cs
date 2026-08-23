using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace DVC.Infrastructure.Persistence
{
    public class DvcDbContext : DbContext
    {
        public DvcDbContext(DbContextOptions<DvcDbContext> options)
            : base(options)
        {
        }
    }

    public class DvcDbContextFactory : IDesignTimeDbContextFactory<DvcDbContext>
    {
        public DvcDbContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<DvcDbContext>();

            optionsBuilder.UseNpgsql(
                "Host=localhost;Port=5432;Database=dvc_dev;Username=postgres;Password=1234");

            return new DvcDbContext(optionsBuilder.Options);
        }
    }
}