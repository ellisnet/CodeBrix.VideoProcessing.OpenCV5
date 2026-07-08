using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.ImgProc; //was previously: OpenCvSharp.Tests.ImgProc;

// ReSharper disable once InconsistentNaming
public class CLAHETests : TestBase
{
    [Fact]
    public void Run()
    {
        using var src = LoadImage("lenna.png", ImreadModes.Grayscale);
        using var dst = new Mat();
        using var clahe = Cv2.CreateCLAHE();
        clahe.Apply(src, dst);
    }

    [Fact]
    public void ClipLimit()
    {
        const double value = 3.14;

        using var clahe = Cv2.CreateCLAHE();
        clahe.ClipLimit = value;
        Assert.Equal(value, clahe.ClipLimit);
    }

    [Fact]
    public void TilesGridSize()
    {
        var value = new Size(1, 2);

        using var clahe = Cv2.CreateCLAHE();
        clahe.TilesGridSize = value;
        Assert.Equal(value, clahe.TilesGridSize);
    }
}
