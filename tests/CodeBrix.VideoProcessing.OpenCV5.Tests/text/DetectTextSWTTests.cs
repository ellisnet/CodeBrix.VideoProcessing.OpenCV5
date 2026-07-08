using CodeBrix.VideoProcessing.OpenCV5.Text;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.Text; //was previously: OpenCvSharp.Tests.Text;

public class DetectTextSWTTests : TestBase
{
    [Fact]
    public void Test()
    {
        using var src = new Mat("_data/image/imageText.png");
        using var draw = new Mat();

        var rects = Cv2.Text.DetectTextSWT(src, true, draw);
        Assert.NotEmpty(rects);

        ShowImagesWhenDebugMode(src, draw);
    }
}
