namespace Presso.API.Application.Interfaces;

using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Rider;
using Presso.API.Domain.Entities;

public interface IRiderService
{
    Task<Result<List<RiderDto>>> GetAllRidersAsync();
    Task<Result<RiderDto>> CreateRiderAsync(CreateRiderRequest request);
    Task<Result<bool>> UpdateAvailabilityAsync(Guid riderId, bool isAvailable);
    Task<Result<bool>> UpdateLocationAsync(Guid riderId, LocationUpdateRequest request);
    Task<Result<RiderJobsResponseDto>> GetRiderJobsAsync(
        Guid riderId,
        string? search = null,
        DateOnly? date = null);
    Task<Result<EarningsDto>> GetEarningsAsync(Guid riderId);
    RiderAssignmentDto ToAssignmentDto(OrderAssignment assignment);
}
