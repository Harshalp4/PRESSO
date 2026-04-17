namespace Presso.API.API.Extensions;

using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Presso.API.Application.Interfaces;
using Presso.API.Application.Services;
using Presso.API.Domain.Entities;
using Presso.API.Infrastructure.Data;
using Presso.API.Infrastructure.ExternalServices;
using Presso.API.Infrastructure.Realtime;
using Presso.API.Infrastructure.Repositories;

public static class ServiceRegistrationExtensions
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services, IConfiguration config)
    {
        // Database
        services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(config.GetConnectionString("DefaultConnection")));

        // Repositories
        services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
        services.AddScoped<IOrderRepository, OrderRepository>();

        // Services
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IOrderService, OrderService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IRiderService, RiderService>();
        services.AddScoped<IAdminService, AdminService>();
        services.AddScoped<ICatalogAdminService, CatalogAdminService>();
        services.AddScoped<ICoinsService, CoinsService>();
        services.AddScoped<IReferralService, ReferralService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<IPaymentService, RazorpayService>();
        services.AddScoped<IFirestoreService, FirestoreService>();
        services.AddScoped<IDailyMessageService, DailyMessageService>();
        services.AddSingleton<IAzureBlobService, AzureBlobService>();

        // SignalR + realtime push abstraction
        services.AddSignalR();
        services.AddScoped<IRealtimePusher, RealtimePusher>();

        // Firebase
        var firebaseKeyPath = config["Firebase:ServiceAccountKeyPath"];
        if (!string.IsNullOrEmpty(firebaseKeyPath) && File.Exists(firebaseKeyPath))
        {
            FirebaseApp.Create(new AppOptions
            {
                Credential = GoogleCredential.FromFile(firebaseKeyPath)
            });
        }

        // AutoMapper
        services.AddAutoMapper(typeof(Application.Mappings.MappingProfile).Assembly);

        // Memory Cache
        services.AddMemoryCache();

        return services;
    }
}
