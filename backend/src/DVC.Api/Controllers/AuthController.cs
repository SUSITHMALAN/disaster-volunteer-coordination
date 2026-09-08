using DVC.Application.Dtos;
using DVC.Application.Services;
using DVC.Domain.Entities;
using DVC.Infrastructure.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DVC.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly DvcDbContext _db;
        private readonly JwtTokenService _tokenService;

        public AuthController(DvcDbContext db, JwtTokenService tokenService)
        {
            _db = db;
            _tokenService = tokenService;
        }

        [HttpPost("register")]
        public async Task<ActionResult<AuthResponse>> Register(RegisterRequest request)
        {
            var emailExists = await _db.Users.AnyAsync(u => u.Email == request.Email);
            if (emailExists)
                return Conflict("A user with this email already exists.");

            var user = new User
            {
                FullName = request.FullName,
                Email = request.Email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                Role = request.Role,
                Skills = request.Skills
            };

            _db.Users.Add(user);
            await _db.SaveChangesAsync();

            var token = _tokenService.GenerateToken(user);

            return Ok(new AuthResponse
            {
                Token = token,
                UserId = user.Id,
                FullName = user.FullName,
                Email = user.Email,
                Role = user.Role.ToString()
            });
        }

        [HttpPost("login")]
        public async Task<ActionResult<AuthResponse>> Login(LoginRequest request)
        {
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                return Unauthorized("Invalid email or password.");

            var token = _tokenService.GenerateToken(user);

            return Ok(new AuthResponse
            {
                Token = token,
                UserId = user.Id,
                FullName = user.FullName,
                Email = user.Email,
                Role = user.Role.ToString()
            });
        }
    }
}