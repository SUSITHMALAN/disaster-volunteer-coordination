using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace DVC.Infrastructure.Persistence
{
    public class DvcDbContextFactory : IDesignTimeDbContextFactory<DvcDbContext>
    {
        public DvcDbContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<DvcDbContext>();

            optionsBuilder.UseNpgsql(
                "Host=aws-0-ap-northeast-1.pooler.supabase.com;Port=5432;Database=postgres;Username=postgres.addzhynkeehvvloknyke;Password=5W3NtUhPJzb1eMlH;Ssl Mode=Require;Trust Server Certificate=true");

            return new DvcDbContext(optionsBuilder.Options);
        }
    }
}