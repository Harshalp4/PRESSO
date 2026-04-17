namespace Presso.API.Domain.Entities;

public class DailyMessage
{
    public Guid Id { get; set; }
    public DateOnly Date { get; set; }
    public string HindiText { get; set; } = string.Empty;
    public string EnglishText { get; set; } = string.Empty;
    public string? Category { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
