using System;
using System.Linq;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.Core;
// Added for CodeBrix: tests for the Mat.ToArray<T> helper (Mat.CodeBrix.cs).

public class MatToArrayTests : TestBase
{
    [Fact]
    public void ToArrayCopiesAnNDimensionalMat()
    {
        // The motivating case: an N-dimensional DNN-style output tensor, which
        // GetArray<T> cannot read (Rows/Cols are -1 when Dims > 2).
        var source = Enumerable.Range(0, 24).Select(i => (float)i).ToArray();
        using var mat = Mat.FromPixelData(new[] { 1, 4, 6 }, MatType.CV_32FC1, source);

        Assert.Equal(-1, mat.Rows);
        Assert.Equal(3, mat.Dims);

        var copied = mat.ToArray<float>();

        Assert.Equal(source, copied);
    }

    [Fact]
    public void ToArrayMatchesGetArrayForATwoDimensionalMat()
    {
        using var mat = new Mat(3, 5, MatType.CV_32FC1);
        Cv2.Randu(mat, 0, 100);

        Assert.True(mat.GetArray(out float[] expected));
        var actual = mat.ToArray<float>();

        Assert.Equal(expected, actual);
    }

    [Fact]
    public void ToArrayReadsMultiChannelMatsAsPrimitivesOrVecs()
    {
        using var mat = new Mat(2, 2, MatType.CV_32FC3, new Scalar(1, 2, 3));

        // Per-channel primitive: 2 x 2 x 3 channels = 12 floats
        var floats = mat.ToArray<float>();
        Assert.Equal(12, floats.Length);
        Assert.Equal(1f, floats[0]);
        Assert.Equal(2f, floats[1]);
        Assert.Equal(3f, floats[2]);

        // Whole-element struct: 4 Vec3f values
        var vecs = mat.ToArray<Vec3f>();
        Assert.Equal(4, vecs.Length);
        Assert.Equal(new Vec3f(1, 2, 3), vecs[0]);
    }

    [Fact]
    public void ToArrayRejectsAMismatchedElementType()
    {
        using var mat = new Mat(2, 2, MatType.CV_32FC1);

        // double (8 bytes) matches neither the per-channel size nor the element size (4)
        Assert.Throws<OpenCvSharpException>(() => mat.ToArray<double>());
        Assert.Throws<OpenCvSharpException>(() => mat.ToArray<byte>());
    }

    [Fact]
    public void ToArrayReturnsEmptyForAnEmptyMat()
    {
        using var mat = new Mat();

        Assert.Empty(mat.ToArray<float>());
    }

    [Fact]
    public void ToArrayRequiresAContinuousMat()
    {
        using var mat = new Mat(10, 10, MatType.CV_8UC1, Scalar.All(7));
        using Mat view = mat.SubMat(new Rect(2, 2, 4, 4));

        Assert.False(view.IsContinuous());
        Assert.Throws<OpenCvSharpException>(() => view.ToArray<byte>());

        // Clone() produces a continuous copy that reads fine
        using Mat clone = view.Clone();
        var bytes = clone.ToArray<byte>();
        Assert.Equal(16, bytes.Length);
        Assert.All(bytes, b => Assert.Equal(7, b));
    }

    [Fact]
    public void ToArrayThrowsAfterDisposal()
    {
        var mat = new Mat(2, 2, MatType.CV_8UC1);
        mat.Dispose();

        Assert.Throws<ObjectDisposedException>(() => mat.ToArray<byte>());
    }
}
