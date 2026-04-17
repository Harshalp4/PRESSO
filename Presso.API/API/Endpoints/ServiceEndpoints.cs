namespace Presso.API.API.Endpoints;

using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Service;
using Presso.API.Application.Interfaces;

public static class ServiceEndpoints
{
    public static RouteGroupBuilder MapServiceEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/services").WithTags("Services");

        group.MapGet("/", async (IRepository<Domain.Entities.Service> serviceRepo, IMapper mapper, IMemoryCache cache) =>
        {
            const string cacheKey = "services_all";
            if (cache.TryGetValue(cacheKey, out List<ServiceDto>? cached) && cached != null)
                return Results.Ok(ApiResponse<List<ServiceDto>>.Ok(cached));

            var services = await serviceRepo.Query()
                .Where(s => s.IsActive)
                .Include(s => s.GarmentTypes.OrderBy(g => g.SortOrder))
                .Include(s => s.Treatments.Where(t => t.IsActive).OrderBy(t => t.SortOrder))
                .OrderBy(s => s.SortOrder)
                .ToListAsync();

            var dtos = services.Select(s => mapper.Map<ServiceDto>(s)).ToList();
            cache.Set(cacheKey, dtos, TimeSpan.FromHours(1));
            return Results.Ok(ApiResponse<List<ServiceDto>>.Ok(dtos));
        });

        return group;
    }
}
