namespace Presso.API.Domain.Enums;

/// <summary>
/// Lifecycle of a rider's admin-approval status. Distinct from
/// <c>IsActive</c> / <c>IsAvailable</c> which describe operational state.
/// </summary>
public enum RiderStatus
{
    /// Admin has created the account but has not reviewed KYC yet.
    /// Rider cannot take jobs.
    Pending = 0,

    /// Admin has approved KYC. Rider can sign in and take jobs.
    Approved = 1,

    /// Admin has temporarily blocked the rider (policy violation, etc.).
    /// Rider record is kept but no new jobs will be dispatched.
    Suspended = 2,

    /// Admin rejected the application. Rider cannot take jobs and the
    /// rejection is final (creates a new account to retry).
    Rejected = 3,
}
