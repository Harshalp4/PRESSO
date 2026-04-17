namespace Presso.API.Application.Services;

using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Presso.API.Application.DTOs.Admin;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;

public class CatalogAdminService : ICatalogAdminService
{
    // Matches the cache key used by the public GET /api/services endpoint.
    // Every write in this service invalidates it so catalog edits show up
    // in the customer app immediately instead of after the 1h TTL.
    private const string ServicesCacheKey = "services_all";

    private readonly IRepository<Service> _serviceRepo;
    private readonly IRepository<GarmentType> _garmentRepo;
    private readonly IRepository<ServiceTreatment> _treatmentRepo;
    private readonly IMemoryCache _cache;

    public CatalogAdminService(
        IRepository<Service> serviceRepo,
        IRepository<GarmentType> garmentRepo,
        IRepository<ServiceTreatment> treatmentRepo,
        IMemoryCache cache)
    {
        _serviceRepo = serviceRepo;
        _garmentRepo = garmentRepo;
        _treatmentRepo = treatmentRepo;
        _cache = cache;
    }

    private void InvalidatePublicCache() => _cache.Remove(ServicesCacheKey);

    // ============================================================
    // Services
    // ============================================================

    public async Task<Result<List<AdminServiceDto>>> GetServicesAsync()
    {
        var services = await _serviceRepo.Query()
            .OrderBy(s => s.SortOrder).ThenBy(s => s.Name)
            .Select(s => new AdminServiceDto(
                s.Id,
                s.Name,
                s.Description,
                s.Category,
                s.PricePerPiece,
                s.Emoji,
                s.IconUrl,
                s.IsActive,
                s.SortOrder,
                s.GarmentTypes.Count,
                s.Treatments.Count))
            .ToListAsync();
        return Result<List<AdminServiceDto>>.Success(services);
    }

    public async Task<Result<AdminServiceDto>> CreateServiceAsync(CreateServiceRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            return Result<AdminServiceDto>.Failure("Service name is required.");
        if (request.PricePerPiece < 0)
            return Result<AdminServiceDto>.Failure("Price cannot be negative.");

        var service = new Service
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim(),
            Category = string.IsNullOrWhiteSpace(request.Category) ? string.Empty : request.Category.Trim(),
            PricePerPiece = request.PricePerPiece,
            Emoji = string.IsNullOrWhiteSpace(request.Emoji) ? null : request.Emoji.Trim(),
            SortOrder = request.SortOrder ?? 0,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
        };

        await _serviceRepo.AddAsync(service);
        await _serviceRepo.SaveChangesAsync();
        InvalidatePublicCache();

        return Result<AdminServiceDto>.Success(new AdminServiceDto(
            service.Id, service.Name, service.Description, service.Category,
            service.PricePerPiece, service.Emoji, service.IconUrl,
            service.IsActive, service.SortOrder, 0, 0));
    }

    public async Task<Result<AdminServiceDto>> UpdateServiceAsync(Guid id, UpdateServiceRequest request)
    {
        var service = await _serviceRepo.Query()
            .Include(s => s.GarmentTypes)
            .Include(s => s.Treatments)
            .FirstOrDefaultAsync(s => s.Id == id);
        if (service == null) return Result<AdminServiceDto>.NotFound("Service not found");

        if (request.Name != null)
        {
            if (string.IsNullOrWhiteSpace(request.Name))
                return Result<AdminServiceDto>.Failure("Service name cannot be empty.");
            service.Name = request.Name.Trim();
        }
        if (request.Description != null)
            service.Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim();
        if (request.Category != null)
            service.Category = request.Category.Trim();
        if (request.PricePerPiece.HasValue)
        {
            if (request.PricePerPiece.Value < 0)
                return Result<AdminServiceDto>.Failure("Price cannot be negative.");
            service.PricePerPiece = request.PricePerPiece.Value;
        }
        if (request.Emoji != null)
            service.Emoji = string.IsNullOrWhiteSpace(request.Emoji) ? null : request.Emoji.Trim();
        if (request.IsActive.HasValue) service.IsActive = request.IsActive.Value;
        if (request.SortOrder.HasValue) service.SortOrder = request.SortOrder.Value;
        service.UpdatedAt = DateTime.UtcNow;

        _serviceRepo.Update(service);
        await _serviceRepo.SaveChangesAsync();
        InvalidatePublicCache();

        return Result<AdminServiceDto>.Success(new AdminServiceDto(
            service.Id, service.Name, service.Description, service.Category,
            service.PricePerPiece, service.Emoji, service.IconUrl,
            service.IsActive, service.SortOrder,
            service.GarmentTypes.Count, service.Treatments.Count));
    }

    // ============================================================
    // Garments
    // ============================================================

    public async Task<Result<List<AdminGarmentDto>>> GetGarmentsAsync(Guid? serviceId)
    {
        var query = _garmentRepo.Query().Include(g => g.Service).AsQueryable();
        if (serviceId.HasValue) query = query.Where(g => g.ServiceId == serviceId.Value);

        var garments = await query
            .OrderBy(g => g.Service.Name).ThenBy(g => g.SortOrder).ThenBy(g => g.Name)
            .Select(g => new AdminGarmentDto(
                g.Id, g.ServiceId, g.Service.Name,
                g.Name, g.Emoji, g.PriceOverride, g.SortOrder))
            .ToListAsync();

        return Result<List<AdminGarmentDto>>.Success(garments);
    }

    public async Task<Result<AdminGarmentDto>> CreateGarmentAsync(CreateGarmentRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            return Result<AdminGarmentDto>.Failure("Garment name is required.");

        var service = await _serviceRepo.GetByIdAsync(request.ServiceId);
        if (service == null) return Result<AdminGarmentDto>.Failure("Parent service not found.");

        var garment = new GarmentType
        {
            Id = Guid.NewGuid(),
            ServiceId = request.ServiceId,
            Name = request.Name.Trim(),
            Emoji = string.IsNullOrWhiteSpace(request.Emoji) ? null : request.Emoji.Trim(),
            PriceOverride = request.PriceOverride,
            SortOrder = request.SortOrder ?? 0,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
        };
        await _garmentRepo.AddAsync(garment);
        await _garmentRepo.SaveChangesAsync();
        InvalidatePublicCache();

        return Result<AdminGarmentDto>.Success(new AdminGarmentDto(
            garment.Id, garment.ServiceId, service.Name,
            garment.Name, garment.Emoji, garment.PriceOverride, garment.SortOrder));
    }

    public async Task<Result<AdminGarmentDto>> UpdateGarmentAsync(Guid id, UpdateGarmentRequest request)
    {
        var garment = await _garmentRepo.Query()
            .Include(g => g.Service)
            .FirstOrDefaultAsync(g => g.Id == id);
        if (garment == null) return Result<AdminGarmentDto>.NotFound("Garment not found");

        if (request.Name != null)
        {
            if (string.IsNullOrWhiteSpace(request.Name))
                return Result<AdminGarmentDto>.Failure("Garment name cannot be empty.");
            garment.Name = request.Name.Trim();
        }
        if (request.Emoji != null)
            garment.Emoji = string.IsNullOrWhiteSpace(request.Emoji) ? null : request.Emoji.Trim();
        if (request.PriceOverride.HasValue || request.PriceOverride == null)
        {
            // PriceOverride is explicitly nullable, so accept null writes too.
            garment.PriceOverride = request.PriceOverride;
        }
        if (request.SortOrder.HasValue) garment.SortOrder = request.SortOrder.Value;
        garment.UpdatedAt = DateTime.UtcNow;

        _garmentRepo.Update(garment);
        await _garmentRepo.SaveChangesAsync();
        InvalidatePublicCache();

        return Result<AdminGarmentDto>.Success(new AdminGarmentDto(
            garment.Id, garment.ServiceId, garment.Service.Name,
            garment.Name, garment.Emoji, garment.PriceOverride, garment.SortOrder));
    }

    public async Task<Result<bool>> DeleteGarmentAsync(Guid id)
    {
        var garment = await _garmentRepo.GetByIdAsync(id);
        if (garment == null) return Result<bool>.NotFound("Garment not found");

        _garmentRepo.Remove(garment);
        try
        {
            await _garmentRepo.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            // OrderItem has a Restrict FK on GarmentTypeId — if any past
            // order references this garment the delete will fail. Surface
            // a friendly error instead of a 500 so the admin knows to
            // rename or archive instead.
            return Result<bool>.Failure(
                "This garment is referenced by existing orders and cannot be deleted.");
        }
        InvalidatePublicCache();
        return Result<bool>.Success(true);
    }

    // ============================================================
    // Treatments
    // ============================================================

    public async Task<Result<List<AdminTreatmentDto>>> GetTreatmentsAsync(Guid? serviceId)
    {
        var query = _treatmentRepo.Query().Include(t => t.Service).AsQueryable();
        if (serviceId.HasValue) query = query.Where(t => t.ServiceId == serviceId.Value);

        var treatments = await query
            .OrderBy(t => t.Service.Name).ThenBy(t => t.SortOrder).ThenBy(t => t.Name)
            .Select(t => new AdminTreatmentDto(
                t.Id, t.ServiceId, t.Service.Name,
                t.Name, t.Description, t.PriceMultiplier, t.IsActive, t.SortOrder))
            .ToListAsync();

        return Result<List<AdminTreatmentDto>>.Success(treatments);
    }

    public async Task<Result<AdminTreatmentDto>> CreateTreatmentAsync(CreateTreatmentRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            return Result<AdminTreatmentDto>.Failure("Treatment name is required.");
        if (request.PriceMultiplier <= 0)
            return Result<AdminTreatmentDto>.Failure("Price multiplier must be greater than zero.");

        var service = await _serviceRepo.GetByIdAsync(request.ServiceId);
        if (service == null) return Result<AdminTreatmentDto>.Failure("Parent service not found.");

        var treatment = new ServiceTreatment
        {
            Id = Guid.NewGuid(),
            ServiceId = request.ServiceId,
            Name = request.Name.Trim(),
            Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim(),
            PriceMultiplier = request.PriceMultiplier,
            SortOrder = request.SortOrder ?? 0,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
        };
        await _treatmentRepo.AddAsync(treatment);
        await _treatmentRepo.SaveChangesAsync();
        InvalidatePublicCache();

        return Result<AdminTreatmentDto>.Success(new AdminTreatmentDto(
            treatment.Id, treatment.ServiceId, service.Name,
            treatment.Name, treatment.Description, treatment.PriceMultiplier,
            treatment.IsActive, treatment.SortOrder));
    }

    public async Task<Result<AdminTreatmentDto>> UpdateTreatmentAsync(Guid id, UpdateTreatmentRequest request)
    {
        var treatment = await _treatmentRepo.Query()
            .Include(t => t.Service)
            .FirstOrDefaultAsync(t => t.Id == id);
        if (treatment == null) return Result<AdminTreatmentDto>.NotFound("Treatment not found");

        if (request.Name != null)
        {
            if (string.IsNullOrWhiteSpace(request.Name))
                return Result<AdminTreatmentDto>.Failure("Treatment name cannot be empty.");
            treatment.Name = request.Name.Trim();
        }
        if (request.Description != null)
            treatment.Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim();
        if (request.PriceMultiplier.HasValue)
        {
            if (request.PriceMultiplier.Value <= 0)
                return Result<AdminTreatmentDto>.Failure("Price multiplier must be greater than zero.");
            treatment.PriceMultiplier = request.PriceMultiplier.Value;
        }
        if (request.IsActive.HasValue) treatment.IsActive = request.IsActive.Value;
        if (request.SortOrder.HasValue) treatment.SortOrder = request.SortOrder.Value;
        treatment.UpdatedAt = DateTime.UtcNow;

        _treatmentRepo.Update(treatment);
        await _treatmentRepo.SaveChangesAsync();
        InvalidatePublicCache();

        return Result<AdminTreatmentDto>.Success(new AdminTreatmentDto(
            treatment.Id, treatment.ServiceId, treatment.Service.Name,
            treatment.Name, treatment.Description, treatment.PriceMultiplier,
            treatment.IsActive, treatment.SortOrder));
    }
}
