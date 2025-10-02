using Azure;
using GraduationProjectWebApplication.Models.DTOs;
using OpenCvSharp;

namespace GraduationProjectWebApplication.Services.FileService
{
    public class FileService : IFileService
    {
        private readonly IWebHostEnvironment _webHostEnvironment;
        public FileService(IWebHostEnvironment webHostEnvironment)
        {
            _webHostEnvironment = webHostEnvironment;
        }

        public async Task<FileResponse> SaveFile(IFormFile file, string folderPath, string fileRootPath, List<string> allowedExtensions)
        {
            FileResponse response = new FileResponse();

            //Get WWWRootPath
            string rootPath = _webHostEnvironment.WebRootPath;

            string imageExtension = Path.GetExtension(file.FileName);
            imageExtension = imageExtension.ToLower();

            if (!allowedExtensions.Contains(imageExtension))
            {
                response.IsSuccess = false;
            }

            string fileName = Guid.NewGuid().ToString() + Path.GetExtension(file.FileName);

            string filePath = Path.Combine(rootPath, folderPath);


            using (var fileStream = new FileStream(Path.Combine(filePath, fileName), FileMode.Create))
            {
                file.CopyTo(fileStream);
            }


            response.IsSuccess = true;
            response.Path = fileRootPath + fileName;

            return response;
        }

        public async Task<FileResponse> UpdateFile(IFormFile newFile, string oldFilePath, string folderPath, string FileRootPath, List<string> allowedExtensions)
        {
            FileResponse response = new FileResponse();

            string imageExtension = Path.GetExtension(newFile.FileName);
            imageExtension = imageExtension.ToLower();

            if (!allowedExtensions.Contains(imageExtension))
            {
                response.IsSuccess = false;
            }

            string rootPath = _webHostEnvironment.WebRootPath;

            string fullOldFilePath = rootPath + oldFilePath;

            if(File.Exists(fullOldFilePath))
                File.Delete(fullOldFilePath);

            string newFileName = Guid.NewGuid().ToString() + Path.GetExtension(newFile.FileName);

            string newFilePath = Path.Combine(rootPath, folderPath);


            using (var fileStream = new FileStream(Path.Combine(newFilePath, newFileName), FileMode.Create))
            {
                newFile.CopyTo(fileStream);
            }


            response.IsSuccess = true;
            response.Path = FileRootPath + newFileName;

            return response;
        }

        public async Task<bool> DeleteFile(string filePath)
        {
            string rootPath = _webHostEnvironment.WebRootPath;

            string fullFilePath = rootPath + filePath;

            if (!File.Exists(fullFilePath))
            {
                return false;
            }

            File.Delete(fullFilePath);

            return true;
        }

        public async Task<string> ConvertToBase64(string input)
        {
            var bytes = System.IO.File.ReadAllBytes(input);
            string base64 = Convert.ToBase64String(bytes);

            return base64;
        }
    }
}
