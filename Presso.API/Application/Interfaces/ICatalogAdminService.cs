namespace Presso.API.Application.Interfaces;

using Presso.API.Application.DTOs.Admin;
using Presso.API.Application.DTOs.Common;

public interface ICatalogAdminService
{
    // Services
    Task<Result<List<AdminServiceDto>>> GetServicesAsync();
    Task<Result<AdminServiceDto>> CreateServiceAsync(CreateServiceRequest request);
    Task<Result<AdminServiceDto>> UpdateServiceAsync(Guid id, UpdateServiceRequest request);

    // Garments
    Task<Result<List<AdminGarmentDto>>> GetGarmentsAsync(Guid? serviceId);
    Task<Result<AdminGarmentDto>> CreateGarmentAsync(CreateGarmentRequest request);
    Task<Result<AdminGarmentDto>> UpdateGarmentAsync(Guid id, UpdateGarmentRequest request);
    Task<Result<bool>> DeleteGarmentAsync(Guid id);

    // Treatments
    Task<Result<List<AdminTreatmentDto>>> GetTreatmentsAsync(Guid? serviceId);
    Task<Result<AdminTreatmentDto>> CreateTreatmentAsync(CreateTreatmentRequest request);
    Task<Result<AdminTreatmentDto>> UpdateTreatmentAsync(Guid id, UpdateTreatmentRequest request);
}
