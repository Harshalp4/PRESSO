namespace Presso.API.Application.Services;

using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Coins;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;

public class CoinsService : ICoinsService
{
    private readonly IRepository<User> _userRepo;
    private readonly IRepository<CoinsLedger> _ledgerRepo;
    private readonly IMapper _mapper;
    private readonly int _coinsPerRupee;

    public CoinsService(IRepository<User> userRepo, IRepository<CoinsLedger> ledgerRepo, IMapper mapper, IConfiguration config)
    {
        _userRepo = userRepo;
        _ledgerRepo = ledgerRepo;
        _mapper = mapper;
        _coinsPerRupee = config.GetValue<int>("OrderSettings:CoinsPerRupee", 10);
    }

    public async Task<Result<BalanceDto>> GetBalanceAsync(Guid userId)
    {
        var user = await _userRepo.GetByIdAsync(userId);
        if (user == null) return Result<BalanceDto>.NotFound("User not found");
        return Result<BalanceDto>.Success(new BalanceDto(user.CoinBalance, user.CoinBalance / (decimal)_coinsPerRupee));
    }

    public async Task<Result<PaginatedResponse<LedgerEntryDto>>> GetHistoryAsync(Guid userId, int page, int pageSize)
    {
        var query = _ledgerRepo.Query()
            .Where(c => c.UserId == userId)
            .Include(c => c.Order);

        var totalCount = await query.CountAsync();
        var entries = await query
            .OrderByDescending(c => c.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return Result<PaginatedResponse<LedgerEntryDto>>.Success(new PaginatedResponse<LedgerEntryDto>
        {
            Items = entries.Select(e => _mapper.Map<LedgerEntryDto>(e)).ToList(),
            TotalCount = totalCount, Page = page, PageSize = pageSize
        });
    }
}
