using DVC.Application.Services;
using DVC.Infrastructure.Services;
using DVC.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Services
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter());
    });

builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter: Bearer {your token}"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins(
                "http://localhost:5173",
                "http://localhost:8080")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Database
var rawConn = builder.Configuration.GetConnectionString("DefaultConnection");

if (string.IsNullOrWhiteSpace(rawConn))
{
    throw new InvalidOperationException(
        "ConnectionStrings:DefaultConnection is not configured.");
}

if (rawConn.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase) ||
    rawConn.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase))
{
    var uri = new Uri(rawConn);
    var userInfo = uri.UserInfo.Split(':');

    var user = Uri.UnescapeDataString(userInfo[0]);

    var pass = userInfo.Length > 1
        ? Uri.UnescapeDataString(userInfo[1])
        : "";

    var db = uri.AbsolutePath.TrimStart('/');

    rawConn =
        $"Host={uri.Host};Port={uri.Port};Database={db};Username={user};Password={pass};";
}

builder.Services.AddDbContext<DvcDbContext>(options =>
    options.UseNpgsql(rawConn));

// Application Services
builder.Services.AddScoped<JwtTokenService>();
builder.Services.AddScoped<IIncidentService, IncidentService>();
builder.Services.AddScoped<IResourceService, ResourceService>();
builder.Services.AddScoped<IReportingService, ReportingService>();
builder.Services.AddScoped<IAssignmentService, AssignmentService>();
builder.Services.AddScoped<IDispatchService, DispatchService>();

// Typed HttpClient for the FastAPI agentic-AI bridge
var agentBaseUrl =
    builder.Configuration["AgentService:BaseUrl"]
    ?? "http://localhost:8000";

builder.Services.AddHttpClient<IAgentWorkflowService, AgentWorkflowService>(client =>
{
    client.BaseAddress = new Uri(agentBaseUrl);
    client.Timeout = TimeSpan.FromSeconds(120);
});

// JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"];

if (string.IsNullOrWhiteSpace(jwtKey))
{
    throw new InvalidOperationException(
        "Jwt:Key is not configured.");
}

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme =
        JwtBearerDefaults.AuthenticationScheme;

    options.DefaultChallengeScheme =
        JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,

        ValidIssuer =
            builder.Configuration["Jwt:Issuer"] ?? "DvcApi",

        ValidAudience =
            builder.Configuration["Jwt:Audience"] ?? "DvcClient",

        IssuerSigningKey =
            new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtKey))
    };
});

builder.Services.AddAuthorization();

var app = builder.Build();

// Pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors("AllowFrontend");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();