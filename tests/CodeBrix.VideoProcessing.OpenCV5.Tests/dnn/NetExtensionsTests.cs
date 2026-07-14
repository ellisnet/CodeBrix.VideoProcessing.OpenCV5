using System;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using CodeBrix.VideoProcessing.OpenCV5.Dnn;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests.Dnn;
// Added for CodeBrix: tests for the Net.ForwardAll extension (NetExtensions.cs).

public class NetExtensionsTests : TestBase
{
    // The native dnn backend is only available on Windows or Linux builds here.
    public static bool IsWindowsOrLinux =>
        RuntimeInformation.IsOSPlatform(OSPlatform.Windows) || RuntimeInformation.IsOSPlatform(OSPlatform.Linux);

    private static string MnistModelPath => Path.Combine("_data", "model", "MNISTTest_tensorflow.pb");

    private static Net CreateNetWithInput(out Mat blob)
    {
        var net = Cv2.Dnn.ReadNetFromTensorflow(MnistModelPath);
        Assert.NotNull(net);

        using var image = LoadImage(Path.Combine("Dnn", "MNIST_9.png"), ImreadModes.Grayscale);
        blob = Cv2.Dnn.BlobFromImage(image, 1.0 / 255, image.Size(), new Scalar(0), swapRB: false, crop: false);
        net!.SetInput(blob);
        return net;
    }

    [Fact(Skip = "Only runs on Windows or Linux", SkipUnless = nameof(IsWindowsOrLinux))]
    public void ForwardAllReturnsEachRequestedLayerOutput()
    {
        using var net = CreateNetWithInput(out var blob);
        using (blob)
        {
            var outputName = net.GetUnconnectedOutLayersNames().Last();
            var midLayerName = net.GetLayerNames().First();

            var outputs = net.ForwardAll(outputName!, midLayerName!);
            try
            {
                Assert.Equal(2, outputs.Length);
                Assert.All(outputs, o => Assert.False(o.Empty()));

                // The first result must be the same data a plain Forward(name) returns
                using var expected = net.Forward(outputName);
                Assert.True(Cv2.Norm(expected, outputs[0], NormTypes.L1) < 1e-5, "outputs differ");
            }
            finally
            {
                foreach (var output in outputs)
                    output.Dispose();
            }
        }
    }

    [Fact(Skip = "Only runs on Windows or Linux", SkipUnless = nameof(IsWindowsOrLinux))]
    public void ForwardAllValidatesItsArguments()
    {
        using var net = CreateNetWithInput(out var blob);
        using (blob)
        {
            Assert.Throws<ArgumentNullException>(() => ((Net)null!).ForwardAll("Identity"));
            Assert.Throws<ArgumentNullException>(() => net.ForwardAll(null!));
            Assert.Throws<ArgumentException>(() => net.ForwardAll());
            Assert.Throws<ArgumentException>(() => net.ForwardAll("", "also-checked-too-late"));
        }
    }
}
