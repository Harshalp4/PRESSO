namespace Presso.API.API.Endpoints;

using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;

public static class PaymentEndpoints
{
    public static RouteGroupBuilder MapPaymentEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/payments").WithTags("Payments");

        group.MapPost("/webhook", async (HttpRequest httpRequest, IPaymentService paymentService) =>
        {
            using var reader = new StreamReader(httpRequest.Body);
            var payload = await reader.ReadToEndAsync();
            var signature = httpRequest.Headers["X-Razorpay-Signature"].FirstOrDefault() ?? "";
            var result = await paymentService.HandleWebhookAsync(payload, signature);
            return result.ToResult();
        }).AllowAnonymous();

        return group;
    }
}
