using System;
using System.ComponentModel.DataAnnotations;

namespace Footy_AI.Models
{
    // ── Request DTOs ───────────────────────────────────────────────────────────

    public class RegisterRequest
    {
        [Required]
        [StringLength(50, MinimumLength = 3)]
        public string Username { get; set; }

        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        [StringLength(100, MinimumLength = 6)]
        public string Password { get; set; }
    }

    public class LoginRequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        public string Password { get; set; }
    }

    // ── Response DTOs ──────────────────────────────────────────────────────────

    public class UserResponse
    {
        public int UserId { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
    }

    public class AuthResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public UserResponse User { get; set; }
    }
}
