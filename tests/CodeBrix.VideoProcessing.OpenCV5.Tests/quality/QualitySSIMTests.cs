using CodeBrix.VideoProcessing.OpenCV5.Quality;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.Quality; //was previously: OpenCvSharp.Tests.Quality;

public class QualitySSIMTests : TestBase
{
    [Fact]
    public void Compute()
    {
        using (var refImage = LoadImage("lenna.png"))
        using (var targetImage = new Mat())
        using (var psnr = QualitySSIM.Create(refImage))
        {
            Cv2.GaussianBlur(refImage, targetImage, new Size(5, 5), 15);

            var value = psnr.Compute(targetImage);
            Assert.Equal(0.72, value[0], 3);
            Assert.Equal(0.793, value[1], 3);
            Assert.Equal(0.863, value[2], 3);
        }
    }

    [Fact]
    public void GetQualityMap()
    {
        using var refImage = LoadImage("lenna.png");
        using var targetImage = new Mat();
        using var psnr = QualitySSIM.Create(refImage);

        Cv2.GaussianBlur(refImage, targetImage, new Size(5, 5), 15);
        psnr.Compute(targetImage);

        using var qualityMap = new Mat();
        psnr.GetQualityMap(qualityMap);

        Assert.False(qualityMap.Empty());
        Assert.Equal(refImage.Size(), qualityMap.Size());
    }

    [Fact]
    public void StaticCompute()
    {
        using (var refImage = LoadImage("lenna.png"))
        using (var targetImage = new Mat())
        {
            Cv2.GaussianBlur(refImage, targetImage, new Size(5, 5), 15);

            var value = QualitySSIM.Compute(refImage, targetImage);
            Assert.Equal(0.72, value[0], 3);
            Assert.Equal(0.793, value[1], 3);
            Assert.Equal(0.863, value[2], 3);
        }
    }
}
