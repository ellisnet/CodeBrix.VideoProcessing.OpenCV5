using System.Diagnostics;
using CodeBrix.VideoProcessing.OpenCV5.XImgProc;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.XImgProc; //was previously: OpenCvSharp.Tests.XImgProc;

public class EdgeFilterTests : TestBase
{
    [Fact]
    public void EnhanceByGuidedFilter()
    {
        using var image = LoadImage("lenna.png", ImreadModes.Color);
        image.ConvertTo(image, MatType.CV_32F, 1.0 / 255.0);

        using var gf = GuidedFilter.Create(image, 16, 0.01);
        using var dst = new Mat();
        gf.Filter(image, dst);

        if (Debugger.IsAttached)
        {
            using Mat view = (image - dst) * 5 + dst;
            Window.ShowImages(image, dst, view);
        }
    }
}
