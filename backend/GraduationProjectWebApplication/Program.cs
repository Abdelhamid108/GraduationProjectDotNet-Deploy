using DotNetEnv;
using GraduationProjectWebApplication.Configuration;
using GraduationProjectWebApplication.Data;
using GraduationProjectWebApplication.Hubs;
using GraduationProjectWebApplication.Models.Entities;
using GraduationProjectWebApplication.Services.AuthenticationSerivce;
using GraduationProjectWebApplication.Services.EmailService;
using GraduationProjectWebApplication.Services.FileService;
using GraduationProjectWebApplication.Services.LettersModelService;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;
using System.Collections;
using System.Text;
using System.Threading.RateLimiting;

namespace GraduationProjectWebApplication
{
    public class Program
    {

        //mabdoon

        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);


            /*==================== Serilog Configurations ===================*/
            Log.Logger = new LoggerConfiguration()
                .MinimumLevel.Debug() // log levels: Debug, Information, Warning, Error
                .Enrich.FromLogContext() // include contextual info
                .WriteTo.Console() // log to console
                .WriteTo.File(
                    "logs/log-.txt",          // path with rolling date
                    rollingInterval: RollingInterval.Day, // new file every day
                    retainedFileCountLimit: 7, // keep 7 days of logs
                    outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}"
                )
                .CreateLogger();

            builder.Host.UseSerilog();

            /*==================== Env Variables ===================*/
            Env.TraversePath().Load();
            foreach (DictionaryEntry env in Environment.GetEnvironmentVariables())
                builder.Configuration[env.Key.ToString()] = env.Value?.ToString();

            string? Key = builder.Configuration["SECRET_KEY"];
            string? Issuer = builder.Configuration["ISSUER"];
            string? ConnectionString = builder.Configuration["DEFAULT_CONNECTION"];
            string? GoogleClientId = builder.Configuration["GOOGLE_CLIENT_ID"];
            string? GoogleClientSecret = builder.Configuration["GOOGLE_CLIENT_SECRET"];

            /*=================== Mail Settings ===================*/
            builder.Services.Configure<MailSettings>(options =>
            {
                options.Host = builder.Configuration["MAIL_HOST"];
                options.Port = int.Parse(builder.Configuration["MAIL_PORT"] ?? "587");
                options.UseSSL = bool.Parse(builder.Configuration["MAIL_USE_SSL"] ?? "false");
                options.Name = builder.Configuration["MAIL_NAME"];
                options.EmailId = builder.Configuration["MAIL_EMAIL_ID"];
                options.UserName = builder.Configuration["MAIL_USERNAME"];
                options.Password = builder.Configuration["MAIL_PASSWORD"];
            });

            builder.Services.PostConfigure<MailSettings>(settings =>
            {
                if (string.IsNullOrWhiteSpace(settings.EmailId))
                    throw new InvalidOperationException("MailSettings not configured.");
            });

            /*=================== Identity & EF Core ===================*/
            builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
                .AddEntityFrameworkStores<ApplicationDbContext>()
                .AddDefaultTokenProviders();

            builder.Services.AddDbContext<ApplicationDbContext>(
                options => options.UseSqlServer(ConnectionString));

            builder.Services.AddControllers();
            builder.Services.AddSignalR();
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();
            builder.Services.AddHttpClient();

            /*=================== Service Injection ===================*/
            builder.Services.AddTransient<IEmailService, EmailService>();
            builder.Services.AddSingleton<IModelService, ModelService>();
            builder.Services.AddScoped<IAuthService, AuthService>();
            builder.Services.AddScoped<IFileService, FileService>();

            /*=================== Authentication ===================*/
            builder.Services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddCookie()
            .AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, x =>
            {
                x.RequireHttpsMetadata = false;
                x.SaveToken = true;
                x.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.ASCII.GetBytes(Key)),
                    ValidateIssuer = true,
                    ValidIssuer = Issuer,
                    ValidateAudience = false,
                    ValidateLifetime = true,
                };
            })
            .AddGoogle(GoogleDefaults.AuthenticationScheme, options =>
            {
                options.ClientId = GoogleClientId;
                options.ClientSecret = GoogleClientSecret;
                options.CallbackPath = "/signin-google";
            });

            /*=================== Swagger ===================*/
            builder.Services.AddSwaggerGen(options =>
            {
                options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Name = "Authorization",
                    Type = SecuritySchemeType.ApiKey,
                    Scheme = "Bearer",
                    BearerFormat = "JWT",
                    In = ParameterLocation.Header,
                    Description = "Enter: Bearer {your JWT token}"
                });

                options.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            { Id = "Bearer", Type = ReferenceType.SecurityScheme }
                        },
                        new List<string>()
                    }
                });

                options.SwaggerDoc("v1", new OpenApiInfo
                {
                    Title = "Ema2a",
                    Version = "v1"
                });
            });

            /*===========================================================
             * RATE LIMITING (CORRECT VERSION)
             ===========================================================*/

            builder.Services.AddRateLimiter(options =>
            {
                /* ---- Global 429 handler ---- */
                options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
                options.OnRejected = async (context, _) =>
                {
                    context.HttpContext.Response.ContentType = "application/json";
                    context.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;

                    await context.HttpContext.Response.WriteAsJsonAsync(new
                    {
                        message = "Rate limit exceeded. Try again later."
                    });
                };

                /* ---- Registration ---- */
                options.AddFixedWindowLimiter("RegisterLimiter", limiter =>
                {
                    limiter.PermitLimit = 5;
                    limiter.Window = TimeSpan.FromMinutes(10);
                    limiter.QueueLimit = 0;
                });

                /* ---- Login ---- */
                options.AddPolicy("LoginLimiter", context =>
                    RateLimitPartition.GetTokenBucketLimiter(
                        context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                        key => new TokenBucketRateLimiterOptions
                        {
                            TokenLimit = 5,
                            TokensPerPeriod = 5,
                            ReplenishmentPeriod = TimeSpan.FromSeconds(10),
                            AutoReplenishment = true,
                            QueueLimit = 0 // No queuing, immediate 429
                        }
                    )
                );

                /* ---- Refresh tokens ---- */
                options.AddFixedWindowLimiter("RefreshTokenLimiter", limiter =>
                {
                    limiter.PermitLimit = 10;
                    limiter.Window = TimeSpan.FromMinutes(1);
                    limiter.QueueLimit = 0;
                });

                /* ---- Reset password ---- */
                options.AddFixedWindowLimiter("GetResetPasswordLimiter", limiter =>
                {
                    limiter.PermitLimit = 3;
                    limiter.Window = TimeSpan.FromHours(1);
                    limiter.QueueLimit = 0;
                });

                options.AddFixedWindowLimiter("ResetPasswordLimiter", limiter =>
                {
                    limiter.PermitLimit = 3;
                    limiter.Window = TimeSpan.FromHours(1);
                    limiter.QueueLimit = 0;
                });

                /* ---- Other authenticated operations ---- */
                options.AddFixedWindowLimiter("ChangePasswordLimiter", limiter =>
                {
                    limiter.PermitLimit = 10;
                    limiter.Window = TimeSpan.FromHours(1);
                    limiter.QueueLimit = 0;
                });

                options.AddFixedWindowLimiter("GoogleLoginLimiter", limiter =>
                {
                    limiter.PermitLimit = 10;
                    limiter.Window = TimeSpan.FromMinutes(1);
                    limiter.QueueLimit = 0;
                });

                options.AddFixedWindowLimiter("GoogleCallbackLimiter", limiter =>
                {
                    limiter.PermitLimit = 10;
                    limiter.Window = TimeSpan.FromMinutes(1);
                    limiter.QueueLimit = 0;
                });

                options.AddFixedWindowLimiter("UpdateImageLimiter", limiter =>
                {
                    limiter.PermitLimit = 10;
                    limiter.Window = TimeSpan.FromMinutes(10);
                    limiter.QueueLimit = 0;
                });

                options.AddFixedWindowLimiter("LogoutLimiter", limiter =>
                {
                    limiter.PermitLimit = 20;
                    limiter.Window = TimeSpan.FromMinutes(1);
                    limiter.QueueLimit = 0;
                });

                options.AddFixedWindowLimiter("UserProfileReadLimiter", limiter =>
                {
                    limiter.PermitLimit = 100;
                    limiter.Window = TimeSpan.FromMinutes(10);
                    limiter.QueueLimit = 0;
                });

                options.AddFixedWindowLimiter("UserProfileUpdateLimiter", limiter =>
                {
                    limiter.PermitLimit = 10;
                    limiter.Window = TimeSpan.FromMinutes(10);
                    limiter.QueueLimit = 0;
                });

                options.AddFixedWindowLimiter("GeminiLimiter", limiter =>
                {
                    limiter.PermitLimit = 3;
                    limiter.Window = TimeSpan.FromMinutes(1);
                    limiter.QueueLimit = 0;
                });

                options.AddFixedWindowLimiter("ArabicLimiter", limiter =>
                {
                    limiter.PermitLimit = 30;
                    limiter.Window = TimeSpan.FromMinutes(1);
                    limiter.QueueLimit = 0;
                });

            });


            ///*=================== Private-CORS ===================*/
            //builder.Services.AddCors(options =>
            //{
            //    options.AddPolicy("AllowPrivateCORS", policy =>
            //    {
            //        policy.WithOrigins("http://127.0.0.1:5500", "http://localhost:5500")
            //              .AllowAnyHeader()
            //              .AllowAnyMethod()
            //              .AllowCredentials();
            //    });
            //});

            /*=================== Public-CORS ===================*/
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowPublicCORS", policy =>
                {
                    policy
                        .SetIsOriginAllowed(origin => true)
                        .AllowAnyHeader()
                        .AllowAnyMethod()
                        .AllowCredentials();

                });
            });

            /*============ To Get User Instance In a service ============*/
            builder.Services.AddHttpContextAccessor();


            var app = builder.Build();

            /*=================== DB Migrations + Roles ===================*/
            using (var scope = app.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                db.Database.Migrate();

                var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
                foreach (var role in new[] { "Admin", "User" })
                {
                    if (!roleManager.RoleExistsAsync(role).Result)
                        roleManager.CreateAsync(new IdentityRole(role)).Wait();
                }
            }

            /*=================== Swagger ===================*/
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            /*=================== Middleware Pipeline ===================*/

            app.UseForwardedHeaders(new ForwardedHeadersOptions
            {
                ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto,
                KnownNetworks = { },
                KnownProxies = { }
            });

            app.UseStaticFiles();
            app.UseRouting();
            app.UseCors("AllowPublicCORS");



            app.UseAuthentication();

            /* ---- Rate Limiter (MUST come here) ---- */
            app.UseRateLimiter();

            /* ---- Custom 429 JSON ---- */
            app.Use(async (context, next) =>
            {
                await next();

                if (context.Response.StatusCode == 429)
                {
                    context.Response.ContentType = "application/json";
                    context.Response.Body.SetLength(0);

                    await context.Response.WriteAsync(
                        "{\"message\": \"Rate limit exceeded. Try again later.\"}"
                    );
                }
            });

            app.UseAuthorization();

            app.MapControllers();
            app.MapHub<SignHub>("/signHub");

            app.Run();
        }
    }
}
