using DVC.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DVC.Infrastructure.Persistence
{
    public class DvcDbContext : DbContext
    {
        public DvcDbContext(DbContextOptions<DvcDbContext> options)
            : base(options)
        {
        }

        public DbSet<Incident> Incidents => Set<Incident>();
        public DbSet<User> Users => Set<User>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<Incident>(entity =>
            {
                entity.HasKey(i => i.Id);

                entity.Property(i => i.Title)
                    .IsRequired()
                    .HasMaxLength(200);

                entity.Property(i => i.Description)
                    .HasMaxLength(2000);

                entity.Property(i => i.Category)
                    .HasConversion<string>()
                    .HasMaxLength(50);

                entity.Property(i => i.Severity)
                    .HasConversion<string>()
                    .HasMaxLength(20);

                entity.Property(i => i.Status)
                    .HasConversion<string>()
                    .HasMaxLength(20);

                entity.Property(i => i.RequiredSkills)
                    .HasColumnType("text[]");
            });

            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(u => u.Id);
                entity.HasIndex(u => u.Email).IsUnique();

                entity.Property(u => u.Email)
                    .IsRequired()
                    .HasMaxLength(256);

                entity.Property(u => u.FullName)
                    .IsRequired()
                    .HasMaxLength(200);

                entity.Property(u => u.Role)
                    .HasConversion<string>()
                    .HasMaxLength(20);

                entity.Property(u => u.Skills)
                    .HasColumnType("text[]");
            });
        }
    }
}