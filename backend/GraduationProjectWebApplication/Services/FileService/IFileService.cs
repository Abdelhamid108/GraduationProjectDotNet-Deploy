using GraduationProjectWebApplication.Models.DTOs;

namespace GraduationProjectWebApplication.Services.FileService
{
    public interface IFileService
    {
        Task<FileResponse> SaveFile(IFormFile file, string folderPath, string fileRootPath, List<string> allowedExtensions);
        Task<FileResponse> UpdateFile(IFormFile newFile, string oldFilePath, string folderPath, string FileRootPath, List<string> allowedExtensions);
        Task<string> ConvertToBase64(string input);
        Task<bool> DeleteFile(string filePath);
    }
}
