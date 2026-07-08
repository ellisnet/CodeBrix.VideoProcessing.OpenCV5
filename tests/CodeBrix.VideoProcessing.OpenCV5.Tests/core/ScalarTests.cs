using System.Runtime.InteropServices;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.Core; //was previously: OpenCvSharp.Tests.Core;

public class ScalarTests
{
    [Fact]
    public void SizeOf()
    {
        Assert.Equal(sizeof(double)*4, Marshal.SizeOf<Scalar>());
    }
}
