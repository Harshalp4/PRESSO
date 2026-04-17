namespace Presso.API.Domain.Entities;

using Presso.API.Domain.Enums;

public class User
{
    public Guid Id { get; set; }
    public string FirebaseUid { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Name { get; set; }
    public string? Email { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsStudentVerified { get; set; }
    public string ReferralCode { get; set; } = string.Empty;
    public UserRole Role { get; set; } = UserRole.Customer;
    public int CoinBalance { get; set; }
    public string? FcmToken { get; set; }
    public DateTime? FcmTokenUpdatedAt { get; set; }
    public string? ProfilePhotoUrl { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Address> Addresses { get; set; } = new List<Address>();
    public ICollection<Order> Orders { get; set; } = new List<Order>();
    public Rider? Rider { get; set; }
    public ICollection<CoinsLedger> CoinsLedgers { get; set; } = new List<CoinsLedger>();
    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
}
