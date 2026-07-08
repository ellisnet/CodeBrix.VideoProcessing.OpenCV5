using CodeBrix.VideoProcessing.OpenCV5.Flann;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.Flann; //was previously: OpenCvSharp.Tests.Flann;

// ArrayProxy migration coverage (issue #1976): CodeBrix.VideoProcessing.OpenCV5.Flann.Index had no test before.
public class IndexTests : TestBase
{
    [Fact]
    public void ConstructAndKnnSearch()
    {
        var features = new float[,]
        {
            { 0, 0 },
            { 10, 0 },
            { 0, 10 },
            { 10, 10 },
        };
        using var featuresMat = Mat.FromPixelData(4, 2, MatType.CV_32FC1, features);
        using var indexParams = new LinearIndexParams();

        using var index = new global::CodeBrix.VideoProcessing.OpenCV5.Flann.Index(featuresMat, indexParams);

        // The nearest point to (1, 1) is (0, 0) at index 0.
        using var searchParams = new SearchParams();
        index.KnnSearch([1f, 1f], out var indices, out var dists, 1, searchParams);

        Assert.Equal(0, indices[0]);
        Assert.True(dists[0] > 0);
    }
}
