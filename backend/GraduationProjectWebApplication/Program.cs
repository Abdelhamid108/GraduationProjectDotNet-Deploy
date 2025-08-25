
using GraduationProjectWebApplication.Services.ModelService;

namespace GraduationProjectWebApplication
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container
            builder.Services.AddControllers();
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();
            builder.Services.AddHttpClient();
            builder.Services.AddScoped<IModelService, ModelService>();


            // Add CORS service
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowAllOrigins",
                    builder => builder.AllowAnyOrigin() // WARNING: Not for production!
                                      .AllowAnyHeader()
                                      .AllowAnyMethod());
            });

            builder.WebHost.UseUrls("http://+:5001");

            var app = builder.Build();

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
