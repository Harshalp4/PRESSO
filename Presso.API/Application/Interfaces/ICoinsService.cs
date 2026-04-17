namespace Presso.API.Application.Interfaces;

using Presso.API.Application.DTOs.Coins;
using Presso.API.Application.DTOs.Common;

public interface ICoinsService
{
    Task<Result<BalanceDto>> GetBalanceAsync(Guid userId);
    Task<Result<PaginatedResponse<LedgerEntryDto>>> GetHistoryAsync(Guid userId, int page, int pageSize);
}
