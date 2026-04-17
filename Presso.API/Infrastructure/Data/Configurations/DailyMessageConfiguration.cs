namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class DailyMessageConfiguration : IEntityTypeConfiguration<DailyMessage>
{
    public void Configure(EntityTypeBuilder<DailyMessage> builder)
    {
        builder.HasKey(d => d.Id);
        builder.HasIndex(d => d.Date).IsUnique();
        builder.Property(d => d.HindiText).HasMaxLength(1000).IsRequired();
        builder.Property(d => d.EnglishText).HasMaxLength(1000).IsRequired();
        builder.Property(d => d.Category).HasMaxLength(50);
    }
}
