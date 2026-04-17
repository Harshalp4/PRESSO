namespace Presso.API.Domain.Entities;

using Presso.API.Domain.Enums;

public class StudentVerification
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string IdPhotoUrl { get; set; } = string.Empty;
    public VerificationStatus Status { get; set; } = VerificationStatus.Pending;
    public string? ReviewNote { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
}
