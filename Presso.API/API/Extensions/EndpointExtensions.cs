namespace Presso.API.API.Extensions;

using Presso.API.API.Endpoints;

public static class EndpointExtensions
{
    public static WebApplication MapAllEndpoints(this WebApplication app)
    {
        app.MapAuthEndpoints();
        app.MapUserEndpoints();
        app.MapAddressEndpoints();
        app.MapServiceEndpoints();
        app.MapSlotEndpoints();
        app.MapOrderEndpoints();
        app.MapPaymentEndpoints();
        app.MapRiderEndpoints();
        app.MapFacilityEndpoints();
        app.MapAdminEndpoints();
        app.MapCoinsEndpoints();
        app.MapReferralEndpoints();
        app.MapNotificationEndpoints();
        app.MapHomeEndpoints();
        app.MapHealthEndpoints();
        app.MapPhotoEndpoints();
        app.MapAdminDiscountEndpoints();
        app.MapStoreEndpoints();
        app.MapAdminStoreEndpoints();
        app.MapConfigEndpoints();
        app.MapServiceZoneEndpoints();
        app.MapAdminServiceZoneEndpoints();
        app.MapErrorLogEndpoints();
        app.MapAdminErrorLogEndpoints();

        return app;
    }
}
