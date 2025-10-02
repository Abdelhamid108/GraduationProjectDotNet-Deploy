using GraduationProjectWebApplication.Data;
using GraduationProjectWebApplication.Models.DTOs;
using GraduationProjectWebApplication.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Net;
using System.Security.Claims;

namespace GraduationProjectWebApplication.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class UserHistoryController : BaseApiController
    {
        ApplicationDbContext _context;
        public UserHistoryController(ApplicationDbContext context)
        {
            _context = context;
        }

        [Authorize]
        [HttpGet("get-user-history")]
        public async Task<ActionResult<APIResponseDTO<List<UserRecordDTO>>>> GetUserHistory()
        {
            try
            {
                var claimsidentity = (ClaimsIdentity)User.Identity;
                string? userId = claimsidentity.FindFirst(ClaimTypes.NameIdentifier).Value;

                List<UserRecord> userRecords = _context.UserRecords.Where(x => x.UserId == userId).ToList();
                List<UserRecordDTO> result = new List<UserRecordDTO>();

                foreach (var record in userRecords)
                {
                    result.Add(new UserRecordDTO()
                    {
                        Id = record.Id,
                        FormedAt = record.FormedAt,
                        FormedSentence = record.FormedSentence
                    });
                }

                return Ok(SuccessResponse<List<UserRecordDTO>>(result));
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An unexpected error occurred");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<bool>($"An unexpected error occurred"));
            }
        }

        [Authorize]
        [HttpDelete("delete-user-history-record")]
        public async Task<ActionResult<APIResponseDTO<bool>>> RemoveUserHistoryRecord([FromBody] DeleteUserRecordDTO deleteUserRecordDTO)
        {
            try
            {
                if (deleteUserRecordDTO == null || deleteUserRecordDTO.Id == 0)
                    return BadRequest(ErrorResponse<bool>("Null Record"));

                UserRecord? userRecord = await _context.UserRecords.FirstOrDefaultAsync(r => r.Id == deleteUserRecordDTO.Id);

                if(userRecord == null)
                    return BadRequest(ErrorResponse<bool>("No Such Record"));

                _context.UserRecords.Remove(userRecord);
                await _context.SaveChangesAsync();

                return Ok(SuccessResponse<bool>(true));
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An unexpected error occurred");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<bool>($"An unexpected error occurred"));
            }
        }

        [Authorize]
        [HttpDelete("delete-all-user-history")]
        public async Task<ActionResult<APIResponseDTO<bool>>> RemoveAllUserHistory()
        {
            try
            {

                var claimsidentity = (ClaimsIdentity)User.Identity;
                string? userId = claimsidentity.FindFirst(ClaimTypes.NameIdentifier).Value;

               

                List<UserRecord>? userRecords =  _context.UserRecords.Where(r => r.UserId == userId).ToList();

                if (!userRecords.Any())
                    return BadRequest(ErrorResponse<bool>("No Records"));

                _context.UserRecords.RemoveRange(userRecords);
                await _context.SaveChangesAsync();

                return Ok(SuccessResponse<bool>(true));
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An unexpected error occurred");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<bool>($"An unexpected error occurred"));
            }
        }
    }
}
