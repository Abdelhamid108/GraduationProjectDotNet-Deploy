using GraduationProjectWebApplication.Models.DTOs;

namespace GraduationProjectWebApplication.Services.LettersModelService
{
    public interface IModelService
    {
        public Task<ModelDetection> ModelRunner(byte[] imageBytes);
    }
}
