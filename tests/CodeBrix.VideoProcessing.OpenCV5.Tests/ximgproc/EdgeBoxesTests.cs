using System;
using CodeBrix.VideoProcessing.OpenCV5.XImgProc;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.XImgProc; //was previously: OpenCvSharp.Tests.XImgProc;

public class EdgeBoxesTests : TestBase
{
    [Fact]
    public void CreateAndDispose1()
    {
        using (var eb = EdgeBoxes.Create())
        {
            GC.KeepAlive(eb);
        }
    }

    [Fact]
    public void CreateAndDispose2()
    {
        using (var eb = Cv2.XImgProc.CreateEdgeBoxes())
        {
            GC.KeepAlive(eb);
        }
    }
}
