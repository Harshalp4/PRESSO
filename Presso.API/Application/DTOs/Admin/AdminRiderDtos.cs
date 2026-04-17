namespace Presso.API.Application.DTOs.Admin;

using Presso.API.Application.DTOs.Common;

public record AdminRiderListItemDto(
    Guid Id,
    Guid UserId,
    string? Name,
    string Phone,
    string? VehicleNumber,
    string Status,
    bool IsActive,
    bool IsAvailable,
    decimal TodayEarnings,
    int CompletedDeliveries,
    DateTime CreatedAt,
    DateTime? ApprovedAt);

public record AdminRiderStatsDto(
    int All,
    int Pending,
    int Approved,
    int Suspended,
    int Rejected);

public record AdminRiderListResponse(
    PaginatedResponse<AdminRiderListItemDto> Riders,
    AdminRiderStatsDto Stats);

public record AdminRiderDetailDto(
    Guid Id,
    Guid UserId,
    string? Name,
    string Phone,
    string? VehicleNumber,
    string Status,
    bool IsActive,
    bool IsAvailable,
    decimal TodayEarnings,
    int CompletedDeliveries,
    int InFlightAssignments,
    double? CurrentLat,
    double? CurrentLng,
    DateTime? LastLocationUpdate,
    DateTime CreatedAt,
    DateTime? ApprovedAt,
    DateTime? SuspendedAt,
    string? RejectionReason,
    string? AdminNotes);

// Request shapes for the three decision endpoints.
public record ApproveRiderRequest(string? AdminNotes);
public record RejectRiderRequest(string Reason, string? AdminNotes);
public record SuspendRiderRequest(string Reason, string? AdminNotes);
public record UpdateRiderNotesRequest(string? AdminNotes);

// Admin-provisioned rider: type-in-phone flow for onboarding riders
// face-to-face before they download the rider app. Admin is vouching
// for them, so the rider is created pre-approved.
public record CreateAdminRiderRequest(
    string Phone,
    string? Name,
    string? VehicleNumber,
    string? AdminNotes);
