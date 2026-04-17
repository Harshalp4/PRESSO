namespace Presso.API.Application.Interfaces;

using Presso.API.Application.DTOs.Common;

public interface IDailyMessageService
{
    Task<Result<DailyMessageDto>> GetTodayMessageAsync();
    Task<Result<string>> GetAiTipAsync(string? context = null);
}

public record DailyMessageDto(string HindiText, string EnglishText, string? Category, DateOnly Date);
