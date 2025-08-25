using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using SixLabors.ImageSharp.PixelFormats;
using Image = SixLabors.ImageSharp.Image;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;
using GraduationProjectWebApplication.DTOs;



namespace GraduationProjectWebApplication.Services.ModelService
{
    public class ModelService : IModelService
    {
        private readonly InferenceSession _onnxSession;
        private readonly DenseTensor<float> _inputTensor;
        private readonly int _modelInputSize = 256;
        private readonly string[] _arabicLabels = StaticDetails.Labels._arabicLabels; // Arabic labels (for display and internal use)
        private readonly string[] _englishLabels = StaticDetails.Labels._englishLabels; // English labels (for debuging)

        // Constants for YOLOv8 processing
        private const int BBOX_ATTRIBUTES = 4; // x, y, width, height
        private const float CONF_THRESHOLD = 0.05f; // Confidence threshold for object detection
        private const float IOU_THRESHOLD = 0.45f; // IoU threshold for Non-Maximum Suppression

        public ModelService()
        {
            var modelPath = Path.Combine(Directory.GetCurrentDirectory(), "Models", "best.onnx");

            if (!System.IO.File.Exists(modelPath))
            {
                throw new FileNotFoundException($"ONNX model file not found at: {modelPath}. " +
                                                "Please ensure 'best.onnx' is in the application's root directory " +
                                                "and its 'Copy to Output Directory' property is set to 'Copy if newer' in Visual Studio.");
            }

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


                for (int y = 0; y < _modelInputSize; y++)
                {
                    for (int x = 0; x < _modelInputSize; x++)
                    {
                        var pixel = image[x, y];
                        _inputTensor[0, 0, y, x] = pixel.R / 255f;
                        _inputTensor[0, 1, y, x] = pixel.G / 255f;
                        _inputTensor[0, 2, y, x] = pixel.B / 255f;
                    }
                }

                var inputs = new List<NamedOnnxValue>
            {
                NamedOnnxValue.CreateFromTensor("images", _inputTensor)
            };

                // Run inference asynchronously
                Tensor<float> output;
                using (var results = await Task.Run(() => _onnxSession.Run(inputs)))
                {
                    output = results.FirstOrDefault(r => r.Name == "output0")?.AsTensor<float>();
                }

                if (output == null)
                {
                    return new ModelDetection()
                    {
                        ErrorMessage = "Model output 'output0' not found or invalid.",
                        FinalDetections = new List<Detection>(),
                        IsSuccess = false
                    };
                }

                // Collect detections
                List<Detection> detections = new List<Detection>();
                int numClasses = _arabicLabels.Length;
                int numDetections = output.Dimensions[2];

                for (int i = 0; i < numDetections; i++)
                {
                    float bbx = output[0, 0, i];
                    float bby = output[0, 1, i];
                    float bbw = output[0, 2, i];
                    float bbh = output[0, 3, i];

                    float maxProb = 0f;
                    int classId = -1;

                    // Vectorized sigmoid loop
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
                            X = bbx,
                            Y = bby,
                            Width = bbw,
                            Height = bbh,
                            Confidence = maxProb,
                            ClassId = classId,
                            ClassLabelArabic = _arabicLabels[classId],
                            ClassLabelEnglish = _englishLabels[classId]
                        });
                    }
                }

                // Apply NMS once after collecting all boxes
                List<Detection> finalDetections = ApplyNMS(detections, IOU_THRESHOLD);

                return new ModelDetection()
                {
                    FinalDetections = finalDetections,
                    IsSuccess = true
                };
            }
            catch (Exception ex)
            {
                return new ModelDetection()
                {
                    
                    IsSuccess = false,
                    ErrorMessage = ex.Message.ToString(),
                };
            }
        }
        private float[] Softmax(float[] scores)
        {
            if (scores == null || scores.Length == 0)
            {
                return new float[0];
            }

            float maxScore = scores.Max();

            float[] expScores = new float[scores.Length];
            for (int i = 0; i < scores.Length; i++)
            {
                expScores[i] = (float)Math.Exp(scores[i] - maxScore);
            }

            float sumExpScores = expScores.Sum();

            float[] softmaxProbabilities = new float[scores.Length];
            for (int i = 0; i < scores.Length; i++)
            {
                softmaxProbabilities[i] = expScores[i] / sumExpScores;
            }

            return softmaxProbabilities;
        }
        private List<Detection> ApplyNMS(List<Detection> detections, float iouThreshold)
        {
            var result = new List<Detection>();
            var orderedDetections = detections.OrderByDescending(d => d.Confidence).ToList();

            while (orderedDetections.Count > 0)
            {
                var bestDetection = orderedDetections[0];
                result.Add(bestDetection);
                orderedDetections.RemoveAt(0);

                orderedDetections = orderedDetections.Where(other =>
                    other.ClassId != bestDetection.ClassId || // Only filter if same class
                    CalculateIoU(bestDetection, other) <= iouThreshold
                ).ToList();
            }

            return result;
        }
        private float CalculateIoU(Detection box1, Detection box2)
        {
            float xA = Math.Max(box1.XMin, box2.XMin);
            float yA = Math.Max(box1.YMin, box2.YMin);
            float xB = Math.Min(box1.XMax, box2.XMax);
            float yB = Math.Min(box1.YMax, box2.YMax);

            float interArea = Math.Max(0, xB - xA) * Math.Max(0, yB - yA);
            float unionArea = box1.Area + box2.Area - interArea;

            return interArea / unionArea;
        }

    }
}
