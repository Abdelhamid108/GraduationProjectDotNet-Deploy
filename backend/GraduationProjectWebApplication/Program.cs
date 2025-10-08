
using DotNetEnv;
using GraduationProjectWebApplication.Configuration;
using GraduationProjectWebApplication.Data;
using GraduationProjectWebApplication.Models.Entities;
using GraduationProjectWebApplication.Services.AuthenticationSerivce;
using GraduationProjectWebApplication.Services.EmailService;
using GraduationProjectWebApplication.Services.FileService;
using GraduationProjectWebApplication.Services.LettersModelService;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Collections;
using System.Text;

namespace GraduationProjectWebApplication
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            Env.TraversePath().Load(); // looks up folders until it finds .env

            foreach (DictionaryEntry env in Environment.GetEnvironmentVariables())
            {
                builder.Configuration[env.Key.ToString()] = env.Value.ToString();
            }


            string? Key = builder.Configuration["SECRET_KEY"];
            string? Issuer = builder.Configuration["ISSUER"];
            string? ConnectionString = builder.Configuration["DEFAULT_CONNECTION"];
            string? GoogleClientId = builder.Configuration["GOOGLE_CLIENT_ID"];
            string? GoogleClientSecret = builder.Configuration["GOOGLE_CLIENT_SECRET"];



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
                    throw new InvalidOperationException("MailSettings are not configured properly.");
            });




            builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
            .AddEntityFrameworkStores<ApplicationDbContext>()
            .AddDefaultTokenProviders();

             builder.Services.AddDbContext<ApplicationDbContext>
                (options => options.UseSqlServer(ConnectionString));

            // Add services to the container
            builder.Services.AddControllers();
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();
            builder.Services.AddHttpClient();

            builder.Services.AddTransient<IEmailService, EmailService>();
            builder.Services.AddScoped<IModelService, ModelService>();
            builder.Services.AddScoped<IAuthService, AuthService>();
            builder.Services.AddScoped<IFileService, FileService>();

            builder.Services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddCookie(CookieAuthenticationDefaults.AuthenticationScheme)
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
                            {
                                Id = "Bearer",
                                Type = ReferenceType.SecurityScheme
                            }
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



            // Add CORS service
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowAllOrigins",
                    builder => builder.AllowAnyOrigin() // WARNING: Not for production!
                                      .AllowAnyHeader()
                                      .AllowAnyMethod());
            });

            //builder.WebHost.UseUrls("http://+:5001");

            var app = builder.Build();

            using (var scope = app.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                db.Database.Migrate();

                var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
                string[] roles = new[] { "Admin", "User" };
                foreach (var role in roles)
                {
                    if (!roleManager.RoleExistsAsync(role).Result)
                    {
                        roleManager.CreateAsync(new IdentityRole(role)).Wait();
                    }
                }
            }

            // Configure the HTTP request pipeline
            if (app.Environment.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            //app.UseHttpsRedirection();

            app.UseRouting();

            app.UseStaticFiles();

            app.UseCors("AllowAllOrigins");

            app.UseAuthorization();

            //app.MapGet("/", context =>
            //{
            //    context.Response.Redirect("/index.html");
            //    return Task.CompletedTask;
            //});

            app.MapControllers();

            app.Run();
        }
    }
}