namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class ExpenseConfiguration : IEntityTypeConfiguration<Expense>
{
    public void Configure(EntityTypeBuilder<Expense> builder)
    {
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Amount).HasPrecision(10, 2);
        builder.Property(e => e.Description).HasMaxLength(500);
        builder.Property(e => e.Reference).HasMaxLength(200);
        builder.HasIndex(e => e.Date);
        builder.HasIndex(e => e.Category);
    }
}
