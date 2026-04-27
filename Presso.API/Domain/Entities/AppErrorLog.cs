namespace Presso.API.Domain.Entities;

public class AppErrorLog
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public string? Phone { get; set; }
    public string ErrorMessage { get; set; } = string.Empty;
    public string? StackTrace { get; set; }
    public string? Screen { get; set; }
    public string? AppVersion { get; set; }
    public string? Platform { get; set; } // android, ios
    public string? DeviceInfo { get; set; }
    public string Severity { get; set; } = "error"; // error, warning, fatal
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
}
