using CodeBrix.VideoProcessing.OpenCV5.XFeatures2D;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.Features; //was previously: OpenCvSharp.Tests.Features;

// ArrayProxy migration coverage (issue #1976): Cv2.AGAST had no test before.
// ReSharper disable once InconsistentNaming
public class AGASTTests : TestBase
{
    [Fact]
    public void Detect()
    {
        using var gray = LoadImage("lenna.png", ImreadModes.Grayscale);

        var keyPoints = Cv2.AGAST(gray, 10, true, AgastFeatureDetector.DetectorType.OAST_9_16);

        Assert.NotEmpty(keyPoints);
    }
}
