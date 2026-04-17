namespace Presso.API.Infrastructure.ExternalServices;

using Azure.AI.OpenAI;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using OpenAI.Chat;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;
using Presso.API.Infrastructure.Data;

public class DailyMessageService : IDailyMessageService
{
    private readonly AppDbContext _context;
    private readonly IConfiguration _config;
    private readonly IMemoryCache _cache;
    private readonly ILogger<DailyMessageService> _logger;
    private readonly bool _aiEnabled;

    public DailyMessageService(AppDbContext context, IConfiguration config, IMemoryCache cache, ILogger<DailyMessageService> logger)
    {
        _context = context;
        _config = config;
        _cache = cache;
        _logger = logger;
        _aiEnabled = config.GetValue<bool>("AzureOpenAI:Enabled");
    }

    public async Task<Result<DailyMessageDto>> GetTodayMessageAsync()
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var cacheKey = $"daily_message_{today}";

        if (_cache.TryGetValue(cacheKey, out DailyMessageDto? cached) && cached != null)
            return Result<DailyMessageDto>.Success(cached);

        var message = await _context.DailyMessages.FirstOrDefaultAsync(m => m.Date == today);
        if (message == null)
        {
            if (!_aiEnabled)
                return Result<DailyMessageDto>.Failure("AI service is not enabled and no pre-generated message exists for today");

            message = await GenerateMessageAsync(today);
            if (message != null)
            {
                _context.DailyMessages.Add(message);
                await _context.SaveChangesAsync();
            }
            else
            {
                return Result<DailyMessageDto>.Failure("Could not generate daily message");
            }
        }

        var dto = new DailyMessageDto(message.HindiText, message.EnglishText, message.Category, message.Date);
        _cache.Set(cacheKey, dto, TimeSpan.FromHours(24));
        return Result<DailyMessageDto>.Success(dto);
    }

    public async Task<Result<string>> GetAiTipAsync(string? context = null)
    {
        if (!_aiEnabled)
            return Result<string>.Failure("AI service is not enabled");

        try
        {
            var (chatClient, deployment) = CreateChatClient();
            if (chatClient == null)
                return Result<string>.Failure("AI service not configured");

            var prompt = "Give a short, helpful laundry care tip" + (context != null ? $" about {context}" : "") + ". Keep it under 100 words.";

            var response = await chatClient.CompleteChatAsync(
                new ChatMessage[] { new SystemChatMessage("You are a helpful laundry care assistant."), new UserChatMessage(prompt) });

            var tip = response.Value.Content[0].Text;
            return Result<string>.Success(tip);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate AI tip");
            return Result<string>.Failure("AI service unavailable");
        }
    }

    private async Task<DailyMessage?> GenerateMessageAsync(DateOnly date)
    {
        try
        {
            var (chatClient, _) = CreateChatClient();
            if (chatClient == null) return null;

            var prompt = $"Generate a motivational/inspirational message for {date:MMMM dd, yyyy}. Respond in JSON: {{\"hindi\": \"...\", \"english\": \"...\", \"category\": \"...\"}}. Keep each message under 150 characters.";

            var response = await chatClient.CompleteChatAsync(
                new ChatMessage[] { new SystemChatMessage("You generate daily motivational messages. Respond only in JSON format."), new UserChatMessage(prompt) });

            var content = response.Value.Content[0].Text;
            var json = System.Text.Json.JsonDocument.Parse(content);

            return new DailyMessage
            {
                Id = Guid.NewGuid(),
                Date = date,
                HindiText = json.RootElement.GetProperty("hindi").GetString() ?? "",
                EnglishText = json.RootElement.GetProperty("english").GetString() ?? "",
                Category = json.RootElement.TryGetProperty("category", out var cat) ? cat.GetString() : null
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate daily message via AI");
            return null;
        }
    }

    private (ChatClient? Client, string? Deployment) CreateChatClient()
    {
        var endpoint = _config["AzureOpenAI:Endpoint"];
        var apiKey = _config["AzureOpenAI:ApiKey"];
        var deployment = _config["AzureOpenAI:DeploymentName"];

        if (string.IsNullOrEmpty(endpoint) || string.IsNullOrEmpty(apiKey))
            return (null, null);

        var client = new AzureOpenAIClient(new Uri(endpoint), new System.ClientModel.ApiKeyCredential(apiKey));
        return (client.GetChatClient(deployment), deployment);
    }
}
