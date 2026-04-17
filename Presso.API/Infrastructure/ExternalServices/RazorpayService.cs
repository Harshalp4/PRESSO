namespace Presso.API.Infrastructure.ExternalServices;

using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Enums;
using Presso.API.Infrastructure.Data;

public class RazorpayService : IPaymentService
{
    private readonly AppDbContext _context;
    private readonly IConfiguration _config;
    private readonly IReferralService _referralService;
    private readonly INotificationService _notificationService;
    private readonly ILogger<RazorpayService> _logger;

    public RazorpayService(
        AppDbContext context,
        IConfiguration config,
        IReferralService referralService,
        INotificationService notificationService,
        ILogger<RazorpayService> logger)
    {
        _context = context;
        _config = config;
        _referralService = referralService;
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task<Result<bool>> HandleWebhookAsync(string payload, string signature)
    {
        var webhookSecret = _config["RazorpaySettings:WebhookSecret"];
        if (!VerifySignature(payload, signature, webhookSecret!))
            return Result<bool>.Unauthorized("Invalid webhook signature");

        try
        {
            var json = System.Text.Json.JsonDocument.Parse(payload);
            var eventType = json.RootElement.GetProperty("event").GetString();

            if (eventType == "payment.captured")
            {
                var paymentEntity = json.RootElement.GetProperty("payload").GetProperty("payment").GetProperty("entity");
                var razorpayOrderId = paymentEntity.GetProperty("order_id").GetString();
                var razorpayPaymentId = paymentEntity.GetProperty("id").GetString();

                var order = await _context.Orders.FirstOrDefaultAsync(o => o.RazorpayOrderId == razorpayOrderId);
                if (order != null)
                {
                    order.PaymentStatus = PaymentStatus.Captured;
                    order.RazorpayPaymentId = razorpayPaymentId;
                    order.Status = OrderStatus.Confirmed;
                    await _context.SaveChangesAsync();

                    // Check if first order for referral reward
                    var orderCount = await _context.Orders.CountAsync(o =>
                        o.UserId == order.UserId && o.PaymentStatus == PaymentStatus.Captured);
                    if (orderCount == 1)
                        await _referralService.RewardReferralAsync(order.UserId);

                    await _notificationService.SendNotificationAsync(order.UserId,
                        "Payment Confirmed", $"Payment for order {order.OrderNumber} confirmed!",
                        NotificationType.OrderUpdate, order.Id);

                    _logger.LogInformation("Payment captured for order {OrderNumber}", order.OrderNumber);
                }
            }
            else if (eventType == "payment.failed")
            {
                var paymentEntity = json.RootElement.GetProperty("payload").GetProperty("payment").GetProperty("entity");
                var razorpayOrderId = paymentEntity.GetProperty("order_id").GetString();

                var order = await _context.Orders.FirstOrDefaultAsync(o => o.RazorpayOrderId == razorpayOrderId);
                if (order != null)
                {
                    order.PaymentStatus = PaymentStatus.Failed;
                    await _context.SaveChangesAsync();

                    await _notificationService.SendNotificationAsync(order.UserId,
                        "Payment Failed", $"Payment for order {order.OrderNumber} failed. Please retry.",
                        NotificationType.OrderUpdate, order.Id);

                    _logger.LogWarning("Payment failed for order {OrderNumber}", order.OrderNumber);
                }
            }

            return Result<bool>.Success(true);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing Razorpay webhook");
            return Result<bool>.Failure("Webhook processing failed");
        }
    }

    private static bool VerifySignature(string payload, string signature, string secret)
    {
        var keyBytes = Encoding.UTF8.GetBytes(secret);
        var payloadBytes = Encoding.UTF8.GetBytes(payload);
        using var hmac = new HMACSHA256(keyBytes);
        var computedHash = hmac.ComputeHash(payloadBytes);
        var computedSignature = Convert.ToHexString(computedHash).ToLowerInvariant();
        return CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(computedSignature),
            Encoding.UTF8.GetBytes(signature));
    }
}
