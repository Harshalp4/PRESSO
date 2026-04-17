namespace Presso.API.API.Endpoints;

using Presso.API.API.Filters;
using Presso.API.Application.DTOs.Admin;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;

public static class AdminEndpoints
{
    public static RouteGroupBuilder MapAdminEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/admin").WithTags("Admin").RequireAuthorization("AdminOnly");

        group.MapGet("/dashboard", async (IAdminService adminService) =>
        {
            var result = await adminService.GetDashboardAsync();
            return result.ToResult();
        });

        group.MapPost("/assign-rider", async (AssignRiderRequest request, IAdminService adminService) =>
        {
            var result = await adminService.AssignRiderAsync(request);
            return result.ToResult();
        }).WithValidation<AssignRiderRequest>();

        group.MapGet("/customers", async (int page, int pageSize, string? search, IAdminService adminService) =>
        {
            var result = await adminService.GetCustomersAsync(page > 0 ? page : 1, pageSize > 0 ? Math.Min(pageSize, 50) : 10, search);
            return result.ToResult();
        });

        group.MapGet("/customers/{id:guid}", async (Guid id, IAdminService adminService) =>
        {
            var result = await adminService.GetCustomerDetailAsync(id);
            return result.ToResult();
        });

        group.MapPatch("/student-verifications/{id:guid}", async (Guid id, ReviewStudentVerificationRequest request, IAdminService adminService) =>
        {
            var result = await adminService.ReviewStudentVerificationAsync(id, request);
            return result.ToResult();
        });

        group.MapGet("/slots", async (IAdminService adminService) =>
        {
            var result = await adminService.GetSlotsAsync();
            return result.ToResult();
        });

        group.MapPost("/slots", async (CreateSlotRequest request, IAdminService adminService) =>
        {
            var result = await adminService.CreateSlotAsync(request);
            return result.ToResult();
        }).WithValidation<CreateSlotRequest>();

        group.MapPatch("/slots/{id:guid}", async (Guid id, UpdateSlotRequest request, IAdminService adminService) =>
        {
            var result = await adminService.UpdateSlotAsync(id, request);
            return result.ToResult();
        });

        group.MapGet("/payments", async (int page, int pageSize, string? status, string? search, IAdminService adminService) =>
        {
            var result = await adminService.GetPaymentsAsync(page > 0 ? page : 1, pageSize > 0 ? Math.Min(pageSize, 50) : 10, status, search);
            return result.ToResult();
        });

        // ============================================================
        // Finance — P&L, Expenses, Payouts
        // ============================================================

        group.MapGet("/finance/pnl", async (int? days, IAdminService adminService) =>
        {
            var result = await adminService.GetPnlAsync(days is > 0 ? days.Value : 30);
            return result.ToResult();
        });

        group.MapGet("/finance/expenses", async (int page, int pageSize, string? category, IAdminService adminService) =>
        {
            var result = await adminService.GetExpensesAsync(page > 0 ? page : 1, pageSize > 0 ? Math.Min(pageSize, 50) : 15, category);
            return result.ToResult();
        });

        group.MapPost("/finance/expenses", async (CreateExpenseRequest request, IAdminService adminService) =>
        {
            var result = await adminService.CreateExpenseAsync(request);
            return result.ToResult();
        });

        group.MapPatch("/finance/expenses/{id:guid}", async (Guid id, UpdateExpenseRequest request, IAdminService adminService) =>
        {
            var result = await adminService.UpdateExpenseAsync(id, request);
            return result.ToResult();
        });

        group.MapDelete("/finance/expenses/{id:guid}", async (Guid id, IAdminService adminService) =>
        {
            var result = await adminService.DeleteExpenseAsync(id);
            return result.ToResult();
        });

        group.MapGet("/finance/payouts", async (int page, int pageSize, string? status, IAdminService adminService) =>
        {
            var result = await adminService.GetPayoutsAsync(page > 0 ? page : 1, pageSize > 0 ? Math.Min(pageSize, 50) : 15, status);
            return result.ToResult();
        });

        group.MapPost("/finance/payouts", async (CreatePayoutRequest request, IAdminService adminService) =>
        {
            var result = await adminService.CreatePayoutAsync(request);
            return result.ToResult();
        });

        group.MapPatch("/finance/payouts/{id:guid}", async (Guid id, UpdatePayoutStatusRequest request, IAdminService adminService) =>
        {
            var result = await adminService.UpdatePayoutStatusAsync(id, request);
            return result.ToResult();
        });

        group.MapGet("/finance/rider-summaries", async (DateOnly from, DateOnly to, IAdminService adminService) =>
        {
            var result = await adminService.GetRiderPayoutSummariesAsync(from, to);
            return result.ToResult();
        });

        group.MapGet("/orders", async (
            int? page,
            int? pageSize,
            string? search,
            string? status,
            Guid? storeId,
            string? range,
            DateTime? from,
            DateTime? to,
            IAdminService adminService) =>
        {
            var result = await adminService.GetOrdersAsync(
                page.GetValueOrDefault(1) > 0 ? page.GetValueOrDefault(1) : 1,
                pageSize.GetValueOrDefault(25) > 0 ? Math.Min(pageSize.GetValueOrDefault(25), 100) : 25,
                search,
                status,
                storeId,
                range,
                from,
                to);
            return result.ToResult();
        });

        group.MapGet("/orders/{id:guid}", async (Guid id, IAdminService adminService) =>
        {
            var result = await adminService.GetOrderDetailForAdminAsync(id);
            return result.ToResult();
        });

        // ============================================================
        // Riders
        // ============================================================

        group.MapGet("/riders", async (
            int? page,
            int? pageSize,
            string? search,
            string? status,
            IAdminService adminService) =>
        {
            var result = await adminService.GetRidersForAdminAsync(
                page.GetValueOrDefault(1) > 0 ? page.GetValueOrDefault(1) : 1,
                pageSize.GetValueOrDefault(25) > 0 ? Math.Min(pageSize.GetValueOrDefault(25), 100) : 25,
                search,
                status);
            return result.ToResult();
        });

        group.MapGet("/riders/{id:guid}", async (Guid id, IAdminService adminService) =>
        {
            var result = await adminService.GetRiderDetailForAdminAsync(id);
            return result.ToResult();
        });

        group.MapPost("/riders", async (CreateAdminRiderRequest request, IAdminService adminService) =>
        {
            var result = await adminService.CreateRiderAsync(request);
            return result.ToResult();
        });

        group.MapPost("/riders/{id:guid}/approve", async (
            Guid id,
            ApproveRiderRequest request,
            IAdminService adminService) =>
        {
            var result = await adminService.ApproveRiderAsync(id, request ?? new ApproveRiderRequest(null));
            return result.ToResult();
        });

        group.MapPost("/riders/{id:guid}/reject", async (
            Guid id,
            RejectRiderRequest request,
            IAdminService adminService) =>
        {
            var result = await adminService.RejectRiderAsync(id, request);
            return result.ToResult();
        });

        group.MapPost("/riders/{id:guid}/suspend", async (
            Guid id,
            SuspendRiderRequest request,
            IAdminService adminService) =>
        {
            var result = await adminService.SuspendRiderAsync(id, request);
            return result.ToResult();
        });

        group.MapPost("/riders/{id:guid}/reinstate", async (
            Guid id,
            IAdminService adminService) =>
        {
            var result = await adminService.ReinstateRiderAsync(id);
            return result.ToResult();
        });

        group.MapPatch("/riders/{id:guid}/notes", async (
            Guid id,
            UpdateRiderNotesRequest request,
            IAdminService adminService) =>
        {
            var result = await adminService.UpdateRiderNotesAsync(id, request);
            return result.ToResult();
        });

        // ============================================================
        // Catalog (Services / Garments / Treatments)
        // ============================================================

        group.MapGet("/catalog/services", async (ICatalogAdminService catalog) =>
            (await catalog.GetServicesAsync()).ToResult());

        group.MapPost("/catalog/services", async (CreateServiceRequest request, ICatalogAdminService catalog) =>
            (await catalog.CreateServiceAsync(request)).ToResult());

        group.MapPatch("/catalog/services/{id:guid}", async (Guid id, UpdateServiceRequest request, ICatalogAdminService catalog) =>
            (await catalog.UpdateServiceAsync(id, request)).ToResult());

        group.MapGet("/catalog/garments", async (Guid? serviceId, ICatalogAdminService catalog) =>
            (await catalog.GetGarmentsAsync(serviceId)).ToResult());

        group.MapPost("/catalog/garments", async (CreateGarmentRequest request, ICatalogAdminService catalog) =>
            (await catalog.CreateGarmentAsync(request)).ToResult());

        group.MapPatch("/catalog/garments/{id:guid}", async (Guid id, UpdateGarmentRequest request, ICatalogAdminService catalog) =>
            (await catalog.UpdateGarmentAsync(id, request)).ToResult());

        group.MapDelete("/catalog/garments/{id:guid}", async (Guid id, ICatalogAdminService catalog) =>
            (await catalog.DeleteGarmentAsync(id)).ToResult());

        group.MapGet("/catalog/treatments", async (Guid? serviceId, ICatalogAdminService catalog) =>
            (await catalog.GetTreatmentsAsync(serviceId)).ToResult());

        group.MapPost("/catalog/treatments", async (CreateTreatmentRequest request, ICatalogAdminService catalog) =>
            (await catalog.CreateTreatmentAsync(request)).ToResult());

        group.MapPatch("/catalog/treatments/{id:guid}", async (Guid id, UpdateTreatmentRequest request, ICatalogAdminService catalog) =>
            (await catalog.UpdateTreatmentAsync(id, request)).ToResult());

        return group;
    }
}
