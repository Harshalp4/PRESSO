namespace Presso.API.Infrastructure.Realtime;

using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

/// <summary>
/// Single notification hub for the operations app. Connections are
/// auto-grouped by role on connect so server code can broadcast to "all
/// facility staff" or "all riders" without tracking individual connection ids.
///
/// The Flutter clients (rider + facility) call /hubs/notifications and listen
/// for the "ReceiveNotification" event. JWT auth comes in via the
/// ?access_token=... query string — see Program.cs for the OnMessageReceived
/// hook that lifts it onto the request.
/// </summary>
[Authorize]
public class NotificationsHub : Hub
{
    public override async Task OnConnectedAsync()
    {
        var role = Context.User?.FindFirst(ClaimTypes.Role)?.Value;
        if (!string.IsNullOrEmpty(role))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"role:{role}");
        }
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var role = Context.User?.FindFirst(ClaimTypes.Role)?.Value;
        if (!string.IsNullOrEmpty(role))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"role:{role}");
        }
        await base.OnDisconnectedAsync(exception);
    }
}
