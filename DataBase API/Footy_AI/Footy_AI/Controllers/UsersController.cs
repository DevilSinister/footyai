using System;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.Cors;
using Footy_AI.Models;

namespace Footy_AI.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    public class UsersController : ApiController
    {
        [HttpPost]
        public IHttpActionResult Register(RegisterRequest request)
        {
            if (request == null || !ModelState.IsValid)
                return BadRequest(ModelState);

            using (var db = new FootballDBEntities())
            {
                bool emailExists = db.User.Any(u =>
                    u.Email.Equals(request.Email, StringComparison.OrdinalIgnoreCase));

                if (emailExists)
                {
                    return Content(HttpStatusCode.Conflict, new AuthResponse
                    {
                        Success = false,
                        Message = "Email is already registered."
                    });
                }

                bool usernameExists = db.User.Any(u =>
                    u.username.Equals(request.Username, StringComparison.OrdinalIgnoreCase));

                if (usernameExists)
                {
                    return Content(HttpStatusCode.Conflict, new AuthResponse
                    {
                        Success = false,
                        Message = "Username is already taken."
                    });
                }

                var user = new User
                {
                    username = request.Username,
                    Email = request.Email,
                    Password = request.Password
                };

                db.User.Add(user);
                db.SaveChanges();

                return Content(HttpStatusCode.Created, new AuthResponse
                {
                    Success = true,
                    Message = "Account created successfully.",
                    User = new UserResponse
                    {
                        UserId = user.User_id,
                        Username = user.username,
                        Email = user.Email
                    }
                });
            }
        }

        [HttpPost]
        public IHttpActionResult Login(LoginRequest request)
        {
            if (request == null || !ModelState.IsValid)
                return BadRequest(ModelState);

            using (var db = new FootballDBEntities())
            {
                var user = db.User.FirstOrDefault(u =>
                    u.Email.Equals(request.Email, StringComparison.OrdinalIgnoreCase) &&
                    u.Password == request.Password);

                if (user == null)
                {
                    return Content(HttpStatusCode.Unauthorized, new AuthResponse
                    {
                        Success = false,
                        Message = "Invalid email or password."
                    });
                }

                return Ok(new AuthResponse
                {
                    Success = true,
                    Message = "Login successful.",
                    User = new UserResponse
                    {
                        UserId = user.User_id,
                        Username = user.username,
                        Email = user.Email
                    }
                });
            }
        }

        [HttpGet]
        public IHttpActionResult GetUserById(int id)
        {
            using (var db = new FootballDBEntities())
            {
                var user = db.User.Find(id);

                if (user == null)
                    return NotFound();

                return Ok(new UserResponse
                {
                    UserId = user.User_id,
                    Username = user.username,
                    Email = user.Email
                });
            }
        }

        [HttpGet]
        public IHttpActionResult GetAllUsers()
        {
            using (var db = new FootballDBEntities())
            {
                db.Configuration.ProxyCreationEnabled = false;

                var users = db.User.Select(u => new UserResponse
                {
                    UserId = u.User_id,
                    Username = u.username,
                    Email = u.Email
                }).ToList();

                return Ok(users);
            }
        }
    }
}