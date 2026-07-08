using System;
using CodeBrix.VideoProcessing.OpenCV5.Internal;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests; //was previously: OpenCvSharp.Tests;

// ReSharper disable InconsistentNaming
public class StdStringTests : TestBase
{
    [Fact]
    public void SimpleNew()
    {
        using var s = new StdString();
        GC.KeepAlive(s);
    }

    [Fact]
    public void ToStringSinglebyte()
    {
        const string value = "https://www.amazon.co.jp/";
        using var s = new StdString(value);
        Assert.Equal(value, s.ToString());
    }

    [Fact]
    public void ToStringMultibyte()
    {
        const string value = "ＯｐｅｎＣＶ";
        using var s = new StdString(value);
        Assert.Equal(value, s.ToString());
    }
}
