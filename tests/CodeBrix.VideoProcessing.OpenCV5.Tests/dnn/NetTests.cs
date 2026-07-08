using CodeBrix.VideoProcessing.OpenCV5.Dnn;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.Dnn; //was previously: OpenCvSharp.Tests.Dnn;

public class NetTests : TestBase
{
    private readonly ITestOutputHelper testOutputHelper;

    public NetTests(ITestOutputHelper testOutputHelper)
    {
        this.testOutputHelper = testOutputHelper;
    }

    [Fact]
    public void Empty()
    {
        using var net = new Net();
        Assert.True(net.Empty());
    }

    [Fact]
    public void GetLayerNames()
    {
        using var net = new Net();
        Assert.Empty(net.GetLayerNames());
    }
}
