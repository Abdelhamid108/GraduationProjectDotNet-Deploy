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
        private readonly ILogger<UserHistoryController> _logger;
        public UserHistoryController(ApplicationDbContext context, ILogger<UserHistoryController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [Authorize]
        [HttpGet("get-user-history")]
        public async Task<ActionResult<APIResponseDTO<List<UserRecordDTO>>>> GetUserHistory()
        {
            _logger.LogInformation("GetUserHistory endpoint called.");

            try
            {
                var claimsIdentity = User.Identity as ClaimsIdentity;
                var userId = claimsIdentity?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (string.IsNullOrEmpty(userId))
                {
                    _logger.LogWarning("GetUserHistory failed: UserId not found in claims.");
                    return Unauthorized(ErrorResponse<string>("Unauthorized"));
                }

                _logger.LogInformation("Fetching history records for UserId: {UserId}", userId);

                // Fetch user records from database
                List<UserRecord> userRecords = await _context.UserRecords
                    .Where(x => x.UserId == userId)
                    .ToListAsync();

                // Map to DTO
                List<UserRecordDTO> result = userRecords.Select(record => new UserRecordDTO
                {
                    Id = record.Id,
                    FormedAt = record.FormedAt,
                    FormedSentence = record.FormedSentence
                }).ToList();

                _logger.LogInformation("Retrieved {Count} history records for UserId: {UserId}", result.Count, userId);

                return Ok(SuccessResponse(result));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred while fetching history for UserId: {UserId}",
                    User?.FindFirstValue(ClaimTypes.NameIdentifier));

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<List<UserRecordDTO>>("An unexpected error occurred"));
            }
        }

        [Authorize]
        [HttpDelete("delete-user-history-record")]
        public async Task<ActionResult<APIResponseDTO<bool>>> RemoveUserHistoryRecord([FromBody] DeleteUserRecordDTO deleteUserRecordDTO)
        {
            _logger.LogInformation("RemoveUserHistoryRecord endpoint called.");

            try
            {
                if (deleteUserRecordDTO == null || deleteUserRecordDTO.Id == 0)
                {
                    _logger.LogWarning("RemoveUserHistoryRecord failed: invalid or null record DTO.");
                    return BadRequest(ErrorResponse<bool>("Null or invalid record"));
                }

                _logger.LogInformation("Attempting to delete user record with Id: {RecordId}", deleteUserRecordDTO.Id);

                UserRecord? userRecord = await _context.UserRecords
                    .FirstOrDefaultAsync(r => r.Id == deleteUserRecordDTO.Id);

                if (userRecord == null)
                {
                    _logger.LogWarning("No user record found with Id: {RecordId}", deleteUserRecordDTO.Id);
                    return BadRequest(ErrorResponse<bool>("No such record"));
                }

                _context.UserRecords.Remove(userRecord);
                await _context.SaveChangesAsync();

                _logger.LogInformation("User record with Id: {RecordId} deleted successfully.", deleteUserRecordDTO.Id);

                return Ok(SuccessResponse<bool>(true));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred while deleting user record with Id: {RecordId}",
                    deleteUserRecordDTO?.Id);

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<bool>("An unexpected error occurred"));
            }
        }

        [Authorize]
        [HttpDelete("delete-all-user-history")]
        public async Task<ActionResult<APIResponseDTO<bool>>> RemoveAllUserHistory()
        {
            _logger.LogInformation("RemoveAllUserHistory endpoint called.");

            try
            {
                var claimsIdentity = User.Identity as ClaimsIdentity;
                var userId = claimsIdentity?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (string.IsNullOrEmpty(userId))
                {
                    _logger.LogWarning("RemoveAllUserHistory failed: UserId not found in claims.");
                    return Unauthorized(ErrorResponse<string>("Unauthorized"));
                }

                _logger.LogInformation("Fetching all history records for UserId: {UserId}", userId);

                var userRecords = await _context.UserRecords
                    .Where(r => r.UserId == userId)
                    .ToListAsync();

                if (!userRecords.Any())
                {
                    _logger.LogWarning("No history records found for UserId: {UserId}", userId);
                    return BadRequest(ErrorResponse<bool>("No records found"));
                }

                _context.UserRecords.RemoveRange(userRecords);
                await _context.SaveChangesAsync();

                _logger.LogInformation("All history records deleted successfully for UserId: {UserId}", userId);

                return Ok(SuccessResponse<bool>(true));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred while deleting all history for UserId: {UserId}",
                    User?.FindFirstValue(ClaimTypes.NameIdentifier));

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<bool>("An unexpected error occurred"));
            }
        }
    }
}
