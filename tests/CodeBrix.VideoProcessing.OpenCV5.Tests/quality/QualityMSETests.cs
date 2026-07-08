using CodeBrix.VideoProcessing.OpenCV5.Quality;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.Quality; //was previously: OpenCvSharp.Tests.Quality;

public class QualityMSETests : TestBase
{
    [Fact]
    public void Compute()
    {
        using (var refImage = LoadImage("lenna.png"))
        using (var targetImage = new Mat())
        using (var psnr = QualityMSE.Create(refImage))
        {
            Cv2.GaussianBlur(refImage, targetImage, new Size(5, 5), 15);

            var value = psnr.Compute(targetImage);
            Assert.Equal(83.89224, value[0], 6);
            Assert.Equal(96.848604, value[1], 6);
            Assert.Equal(50.611845, value[2], 6);
        }
    }

    [Fact]
    public void StaticCompute()
    {
        using (var refImage = LoadImage("lenna.png"))
        using (var targetImage = new Mat())
        {
            Cv2.GaussianBlur(refImage, targetImage, new Size(5, 5), 15);

            var value = QualityMSE.Compute(refImage, targetImage);
            Assert.Equal(83.89224, value[0], 6);
            Assert.Equal(96.848604, value[1], 6);
            Assert.Equal(50.611845, value[2], 6);
        }
    }
}
