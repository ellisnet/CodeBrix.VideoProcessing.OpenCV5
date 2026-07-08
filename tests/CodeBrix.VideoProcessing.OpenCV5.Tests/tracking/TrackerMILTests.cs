using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.Tracking; //was previously: OpenCvSharp.Tests.Tracking;

// ReSharper disable once InconsistentNaming
public class TrackerMILTests : TrackerTestBase
{
    [Fact]
    public void Init()
    {
        using var tracker = TrackerMIL.Create();
        InitBase(tracker);
    }

    [Fact]
    public void Update()
    {
        using var tracker = TrackerMIL.Create();
        UpdateBase(tracker);
    }
}
