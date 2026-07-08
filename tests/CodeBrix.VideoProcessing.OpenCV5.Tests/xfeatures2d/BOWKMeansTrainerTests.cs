using CodeBrix.VideoProcessing.OpenCV5.XFeatures2D;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.XFeatures2D; //was previously: OpenCvSharp.Tests.XFeatures2D;

public class BOWKMeansTrainerTests : TestBase
{
    [Fact]
    public void New()
    {
        var bow = new BOWKMeansTrainer(100);
        bow.Dispose();
    }
}
