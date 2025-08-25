
using GraduationProjectWebApplication.DTOs;

namespace GraduationProjectWebApplication.Services.ModelService
{
    public interface IModelService
    {
        public Task<ModelDetection> ModelRunner(byte[] imageBytes);
    }
}
