namespace Presso.API.Application.Interfaces;

/// <summary>
/// Thin abstraction over the SignalR hub so endpoints/services can broadcast
/// realtime events without taking a direct dependency on SignalR types. Keeps
/// the application layer testable and lets us swap transports later.
/// </summary>
public interface IRealtimePusher
{
    /// <summary>Broadcasts an event to every connected client in a role group (e.g. "FacilityStaff").</summary>
    Task PushToRoleAsync(string role, string eventName, object payload);

    /// <summary>Broadcasts an event to a specific user across all of their devices.</summary>
    Task PushToUserAsync(Guid userId, string eventName, object payload);
}
