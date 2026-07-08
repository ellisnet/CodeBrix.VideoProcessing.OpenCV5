using CodeBrix.VideoProcessing.OpenCV5.ML;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.Core; //was previously: OpenCvSharp.Tests.Core;

public class AlgorithmTests : TestBase
{
    [Fact]
    public void GetDefaultName()
    {
        using (var model = SVM.Create())
        {
            Assert.Equal("opencv_ml_svm", model.GetDefaultName());
        }
    }
}
