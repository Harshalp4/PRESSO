namespace Presso.API.Application.Mappings;

using AutoMapper;
using Presso.API.Application.DTOs.Auth;
using Presso.API.Application.DTOs.Coins;
using Presso.API.Application.DTOs.Notification;
using Presso.API.Application.DTOs.Order;
using Presso.API.Application.DTOs.Referral;
using Presso.API.Application.DTOs.Rider;
using Presso.API.Application.DTOs.Service;
using Presso.API.Application.DTOs.Store;
using Presso.API.Application.DTOs.User;
using Presso.API.Domain.Entities;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<User, UserProfileDto>()
            .ForCtorParam("Role", opt => opt.MapFrom(src => src.Role.ToString()));

        CreateMap<Address, AddressDto>();
        CreateMap<CreateAddressRequest, Address>();

        CreateMap<Domain.Entities.Service, ServiceDto>();
        CreateMap<GarmentType, GarmentTypeDto>();
        CreateMap<ServiceTreatment, ServiceTreatmentDto>();

        CreateMap<Order, OrderDto>()
            .ForCtorParam("Status", opt => opt.MapFrom(src => src.Status.ToString()))
            .ForCtorParam("PaymentStatus", opt => opt.MapFrom(src => src.PaymentStatus.ToString()))
            .ForCtorParam("PickupSlotDisplay", opt => opt.MapFrom(src =>
                src.PickupSlot != null && src.PickupDate.HasValue
                    ? $"{src.PickupDate.Value:yyyy-MM-dd} {src.PickupSlot.StartTime:HH:mm}-{src.PickupSlot.EndTime:HH:mm}"
                    : null));

        CreateMap<Order, OrderDetailDto>()
            .ForCtorParam("Status", opt => opt.MapFrom(src => src.Status.ToString()))
            .ForCtorParam("PaymentStatus", opt => opt.MapFrom(src => src.PaymentStatus.ToString()))
            .ForCtorParam("FacilityInfo", opt => opt.MapFrom(src =>
                src.AssignedStore != null
                    ? new FacilityInfoDto(src.AssignedStore.Name,
                        src.AssignedStore.AddressLine1 + (src.AssignedStore.AddressLine2 != null ? ", " + src.AssignedStore.AddressLine2 : ""),
                        src.AssignedStore.Phone, src.AssignedStore.GoogleMapsUrl)
                    : null))
            // Only expose the plaintext delivery OTP while the order is
            // actually out-for-delivery. In every other state the mapper
            // returns null so the customer UI never has to decide whether
            // to show a stale OTP.
            .ForCtorParam("DeliveryOtp", opt => opt.MapFrom(src =>
                src.Status == Domain.Enums.OrderStatus.OutForDelivery
                    ? src.DeliveryOtp
                    : null));

        CreateMap<OrderItem, OrderItemDto>();

        // Slots are date-less templates so neither Date nor Available can be
        // computed from the entity alone — callers (OrderService /
        // OrderDetailDto mapping) supply them by hand.
        CreateMap<PickupSlot, SlotDto>()
            .ForCtorParam("Date", opt => opt.MapFrom(_ => (DateOnly?)null))
            .ForCtorParam("Available", opt => opt.MapFrom(src => src.MaxOrders));

        CreateMap<OrderAssignment, AssignmentDto>()
            .ForCtorParam("RiderName", opt => opt.MapFrom(src => src.Rider.User.Name))
            .ForCtorParam("Type", opt => opt.MapFrom(src => src.Type.ToString()))
            .ForCtorParam("Status", opt => opt.MapFrom(src => src.Status.ToString()));

        CreateMap<Rider, RiderDto>()
            .ForCtorParam("Name", opt => opt.MapFrom(src => src.User.Name))
            .ForCtorParam("Phone", opt => opt.MapFrom(src => src.User.Phone));

        CreateMap<CoinsLedger, LedgerEntryDto>()
            .ForCtorParam("Type", opt => opt.MapFrom(src => src.Type.ToString()))
            .ForCtorParam("OrderNumber", opt => opt.MapFrom(src => src.Order != null ? src.Order.OrderNumber : null));

        CreateMap<Referral, ReferralHistoryDto>()
            .ForCtorParam("ReferredUserName", opt => opt.MapFrom(src => src.ReferredUser.Name))
            .ForCtorParam("Status", opt => opt.MapFrom(src => src.Status.ToString()));

        CreateMap<Domain.Entities.Notification, NotificationDto>()
            .ForCtorParam("Type", opt => opt.MapFrom(src => src.Type.ToString()));
    }
}
