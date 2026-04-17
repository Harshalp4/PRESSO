namespace Presso.API.Application.DTOs.Coins;

public record BalanceDto(int Balance, decimal ValueInRupees);

public record LedgerEntryDto(
    Guid Id, int Amount, string Type, string Description,
    string? OrderNumber, DateTime CreatedAt);
