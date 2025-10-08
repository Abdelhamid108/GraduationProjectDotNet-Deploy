using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using GraduationProjectWebApplication.Models.DTOs;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace GraduationProjectWebApplication.Services.LettersModelService
{
    
    public class ModelService : IModelService
    {
        private readonly InferenceSession _onnxSession;
        private readonly DenseTensor<float> _inputTensor;
        private readonly int _modelInputSize = 256;
        private readonly string[] _arabicLabels = GraduationProject.StaticDetails.Labels._arabicLabels;
        private readonly string[] _englishLabels = GraduationProject.StaticDetails.Labels._englishLabels;

        private const int BBOX_ATTRIBUTES = 4;
        private const float CONF_THRESHOLD = 0.05f;
        private const float IOU_THRESHOLD = 0.45f;

        public ModelService()
        {
            var modelPath = Path.Combine(Directory.GetCurrentDirectory(), "AIModels", "best.onnx");

            if (!File.Exists(modelPath))
            {
                throw new FileNotFoundException($"ONNX model file not found at: {modelPath}.");
            }

            // For production environments, consider using SessionOptions for performance tuning
            // e.g., sessionOptions.ExecutionMode = ExecutionMode.ORT_SEQUENTIAL;
            // sessionOptions.GraphOptimizationLevel = GraphOptimizationLevel.ORT_ENABLE_ALL;
            _onnxSession = new InferenceSession(modelPath);
            _inputTensor = new DenseTensor<float>(new[] { 1, 3, _modelInputSize, _modelInputSize });
        }

        public async Task<ModelDetection> ModelRunner(byte[] imageBytes)
        {
            try
            {
                using var image = Image.Load<Rgb24>(imageBytes);
                if (image.Width != _modelInputSize || image.Height != _modelInputSize)
                {
                    image.Mutate(x => x.Resize(new Size(_modelInputSize, _modelInputSize)));
                }

                image.ProcessPixelRows(accessor =>
                {
                    for (int y = 0; y < accessor.Height; y++)
                    {
                        Span<Rgb24> pixelRow = accessor.GetRowSpan(y);
                        for (int x = 0; x < accessor.Width; x++)
                        {
                            _inputTensor[0, 0, y, x] = pixelRow[x].R / 255f;
                            _inputTensor[0, 1, y, x] = pixelRow[x].G / 255f;
                            _inputTensor[0, 2, y, x] = pixelRow[x].B / 255f;
                        }
                    }
                });

                var inputs = new List<NamedOnnxValue>
                {
                    NamedOnnxValue.CreateFromTensor("images", _inputTensor)
                };

                using var results = await Task.Run(() => _onnxSession.Run(inputs));
                var output = results.FirstOrDefault(r => r.Name == "output0")?.AsTensor<float>();

                if (output == null)
                {
                    return new ModelDetection { ErrorMessage = "Model output 'output0' not found.", IsSuccess = false };
                }

                int numDetections = output.Dimensions[2];
                var detections = new List<Detection>(numDetections);
                int numClasses = _arabicLabels.Length;

                for (int i = 0; i < numDetections; i++)
                {
                    float maxProb = 0f;
                    int classId = -1;

                    for (int k = 0; k < numClasses; k++)
                    {
                        float prob = 1f / (1f + MathF.Exp(-output[0, BBOX_ATTRIBUTES + k, i]));
                        if (prob > maxProb)
                        {
                            maxProb = prob;
                            classId = k;
                        }
                    }

                    if (maxProb > CONF_THRESHOLD)
                    {
                        detections.Add(new Detection
                        {
                            X = output[0, 0, i],
                            Y = output[0, 1, i],
                            Width = output[0, 2, i],
                            Height = output[0, 3, i],
                            Confidence = maxProb,
                            ClassId = classId,
                            ClassLabelArabic = _arabicLabels[classId],
                            ClassLabelEnglish = _englishLabels[classId]
                        });
                    }
                }

                List<Detection> finalDetections = ApplyNMS(detections, IOU_THRESHOLD);

                return new ModelDetection { FinalDetections = finalDetections, IsSuccess = true };
            }
            catch (Exception ex)
            {
                
                return new ModelDetection { IsSuccess = false, ErrorMessage = ex.Message };
            }
        }

        

        private List<Detection> ApplyNMS(List<Detection> detections, float iouThreshold)
        {
            if (detections.Count == 0) return detections;

            var finalDetections = new List<Detection>();

            detections.Sort((a, b) => b.Confidence.CompareTo(a.Confidence));

            while (detections.Count > 0)
            {
                var bestDetection = detections[0];
                finalDetections.Add(bestDetection);
                detections.RemoveAt(0);

                detections.RemoveAll(other =>
                    other.ClassId == bestDetection.ClassId && 
                    CalculateIoU(bestDetection, other) > iouThreshold
                );
            }

            return finalDetections;
        }

        private float CalculateIoU(Detection box1, Detection box2)
        {
            float xA = Math.Max(box1.XMin, box2.XMin);
            float yA = Math.Max(box1.YMin, box2.YMin);
            float xB = Math.Min(box1.XMax, box2.XMax);
            float yB = Math.Min(box1.YMax, box2.YMax);

            float interArea = Math.Max(0, xB - xA) * Math.Max(0, yB - yA);
            float unionArea = box1.Area + box2.Area - interArea;

            return unionArea > 0 ? interArea / unionArea : 0;
        }
    }
}