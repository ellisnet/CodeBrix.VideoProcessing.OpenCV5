using CodeBrix.VideoProcessing.OpenCV5.Dnn;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.Dnn; //was previously: OpenCvSharp.Tests.Dnn;

public class DnnTests : TestBase
{
    [Fact]
    public void NMSBoxes()
    {
        var bboxes = new[] {
            new Rect(10, 10, 20, 20),
            new Rect(100, 100, 20, 20),
            new Rect(1000, 1000, 20, 20)
        };
        var scores = new [] { 1.0f, 0.1f, 0.6f };
        float scoreThreshold = 0.5f;
        float nmsThreshold = 0.4f;

        Cv2.Dnn.NMSBoxes(bboxes, scores, scoreThreshold, nmsThreshold, out var indices);

        Assert.Equal(2, indices.Length);
        Assert.Equal(0, indices[0]);
        Assert.Equal(2, indices[1]);
    }
}
