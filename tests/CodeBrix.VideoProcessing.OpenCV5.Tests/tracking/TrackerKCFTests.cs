using System;
using CodeBrix.VideoProcessing.OpenCV5.Tracking;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.Tracking; //was previously: OpenCvSharp.Tests.Tracking;

// ReSharper disable once InconsistentNaming
public class TrackerKCFTests : TrackerTestBase
{
    [Fact]
    public void Init()
    {
        using var tracker = TrackerKCF.Create();
        InitBase(tracker);
    }

    // https://github.com/shimat/opencvsharp/issues/459
    [Fact]
    public void Issue459()
    {
        var paras = new TrackerKCF.Params
        {
            CompressFeature = true,
            CompressedSize = 1,
            Resize = true,
            DescNpca = 1,
            DescPca = 1
        };

        using var tracker = TrackerKCF.Create(paras);
        GC.KeepAlive(tracker);
    }

    [Fact]
    public void Update()
    {
        using var tracker = TrackerKCF.Create();
        UpdateBase(tracker);
    }
}
