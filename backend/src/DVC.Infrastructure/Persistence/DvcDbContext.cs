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

        public DbSet<VolunteerMatch> VolunteerMatches => Set<VolunteerMatch>();

        public DbSet<IncidentResource> IncidentResources => Set<IncidentResource>();
        public DbSet<Assignment> Assignments => Set<Assignment>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Incident configuration
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

            // User configuration
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(u => u.Id);

                entity.ToTable("Users");

                entity.HasIndex(u => u.Email)
                    .IsUnique();

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

                entity.Property(u => u.Certifications)
                    .HasColumnType("text[]");

                entity.Property(u => u.ComfortTier)
                    .HasConversion<string>()
                    .HasMaxLength(20);

                entity.Property(u => u.MaximumActiveAssignments)
                    .IsRequired();

                entity.Property(u => u.AvailabilityStartUtc)
                    .IsRequired(false);

                entity.Property(u => u.AvailabilityEndUtc)
                    .IsRequired(false);
            });

            // Incident resource configuration
            modelBuilder.Entity<IncidentResource>(entity =>
            {
                entity.HasKey(r => r.Id);

                entity.ToTable("IncidentResources", table =>
                {
                    table.HasCheckConstraint("CK_IncidentResources_AvailableQuantity_NonNegative",
                        "\"AvailableQuantity\" >= 0");
                    table.HasCheckConstraint("CK_IncidentResources_NeededQuantity_NonNegative",
                        "\"NeededQuantity\" >= 0");
                    table.HasCheckConstraint("CK_IncidentResources_UsedQuantity_NonNegative",
                        "\"UsedQuantity\" >= 0");
                    table.HasCheckConstraint("CK_IncidentResources_UsedQuantity_WithinAllocation",
                        "\"UsedQuantity\" <= \"AvailableQuantity\"");
                });

                entity.Property(r => r.ResourceName)
                    .IsRequired()
                    .HasMaxLength(200);

                entity.Property(r => r.Category)
                    .HasConversion<string>()
                    .HasMaxLength(50);

                entity.Property(r => r.Unit)
                    .IsRequired()
                    .HasMaxLength(50);

                entity.Property(r => r.AvailableQuantity).HasPrecision(18, 2);
                entity.Property(r => r.NeededQuantity).HasPrecision(18, 2);
                entity.Property(r => r.UsedQuantity).HasPrecision(18, 2);

                entity.Ignore(r => r.HasShortage);
                entity.Ignore(r => r.ShortageQuantity);
                entity.Ignore(r => r.RemainingQuantity);

                entity.HasOne(r => r.Incident)
                    .WithMany()
                    .HasForeignKey(r => r.IncidentId)
                    .IsRequired()
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasIndex(r => r.IncidentId);
            });

            // Volunteer match configuration
            modelBuilder.Entity<VolunteerMatch>(entity =>
            {
                entity.HasKey(m => m.Id);

                entity.Property(m => m.Status)
                    .HasConversion<string>()
                    .HasMaxLength(20);

                entity.HasOne(m => m.Incident)
                    .WithMany()
                    .HasForeignKey(m => m.IncidentId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(m => m.Volunteer)
                    .WithMany()
                    .HasForeignKey(m => m.VolunteerId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Assignment configuration
            modelBuilder.Entity<Assignment>(entity =>
            {
                entity.HasKey(a => a.Id);

                entity.Property(a => a.Status)
                    .HasConversion<string>()
                    .HasMaxLength(20);

                entity.Property(a => a.EstimatedDurationMinutes)
                    .IsRequired();

                entity.Property(a => a.AssignedAtUtc)
                    .IsRequired();

                entity.Property(a => a.CreatedAtUtc)
                    .IsRequired();

                entity.HasOne(a => a.Incident)
                    .WithMany()
                    .HasForeignKey(a => a.IncidentId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(a => a.Volunteer)
                    .WithMany()
                    .HasForeignKey(a => a.VolunteerId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(a => a.Match)
                    .WithMany()
                    .HasForeignKey(a => a.MatchId)
                    .OnDelete(DeleteBehavior.Restrict);
            });
        }
    }
}
