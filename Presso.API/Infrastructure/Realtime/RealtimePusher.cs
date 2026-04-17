namespace Presso.API.Infrastructure.Realtime;

using Microsoft.AspNetCore.SignalR;
using Presso.API.Application.Interfaces;

public class RealtimePusher : IRealtimePusher
{
    private readonly IHubContext<NotificationsHub> _hub;

    public RealtimePusher(IHubContext<NotificationsHub> hub)
    {
        _hub = hub;
    }

    public Task PushToRoleAsync(string role, string eventName, object payload)
        => _hub.Clients.Group($"role:{role}").SendAsync(eventName, payload);

    public Task PushToUserAsync(Guid userId, string eventName, object payload)
        => _hub.Clients.User(userId.ToString()).SendAsync(eventName, payload);
}
