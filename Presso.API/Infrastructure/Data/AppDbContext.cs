namespace Presso.API.Infrastructure.Data;

using Microsoft.EntityFrameworkCore;
using Presso.API.Domain.Entities;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Address> Addresses => Set<Address>();
    public DbSet<Service> Services => Set<Service>();
    public DbSet<GarmentType> GarmentTypes => Set<GarmentType>();
    public DbSet<PickupSlot> PickupSlots => Set<PickupSlot>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<OrderAssignment> OrderAssignments => Set<OrderAssignment>();
    public DbSet<Rider> Riders => Set<Rider>();
    public DbSet<CoinsLedger> CoinsLedgers => Set<CoinsLedger>();
    public DbSet<Referral> Referrals => Set<Referral>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<DailyMessage> DailyMessages => Set<DailyMessage>();
    public DbSet<StudentVerification> StudentVerifications => Set<StudentVerification>();
    public DbSet<UserDiscount> UserDiscounts => Set<UserDiscount>();
    public DbSet<StoreLocation> StoreLocations => Set<StoreLocation>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<ServiceTreatment> ServiceTreatments => Set<ServiceTreatment>();
    public DbSet<AppConfig> AppConfigs => Set<AppConfig>();
    public DbSet<ServiceZone> ServiceZones => Set<ServiceZone>();
    public DbSet<Expense> Expenses => Set<Expense>();
    public DbSet<RiderPayout> RiderPayouts => Set<RiderPayout>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.HasSequence<int>("OrderNumberSequence").StartsAt(1).IncrementsBy(1);

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var entries = ChangeTracker.Entries()
            .Where(e => e.State == EntityState.Modified);

        foreach (var entry in entries)
        {
            var updatedAtProp = entry.Properties.FirstOrDefault(p => p.Metadata.Name == "UpdatedAt");
            if (updatedAtProp != null)
                updatedAtProp.CurrentValue = DateTime.UtcNow;
        }

        return await base.SaveChangesAsync(cancellationToken);
    }
}
