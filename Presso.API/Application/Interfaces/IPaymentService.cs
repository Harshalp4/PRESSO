namespace Presso.API.Application.Interfaces;

using Presso.API.Application.DTOs.Common;

public interface IPaymentService
{
    Task<Result<bool>> HandleWebhookAsync(string payload, string signature);
}
