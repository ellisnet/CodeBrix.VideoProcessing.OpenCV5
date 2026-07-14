using System;

namespace CodeBrix.VideoProcessing.OpenCV5.Dnn;
//Added for CodeBrix (not an upstream OpenCvSharp file): helper extensions for Net.

/// <summary>
/// CodeBrix helper extensions for <see cref="Net"/>.
/// </summary>
public static class NetExtensions
{
    /// <summary>
    /// Runs a forward pass and returns the output of EACH named layer - the reliable way
    /// to read multiple outputs from one network.
    /// <para/>
    /// Background: the multi-output <see cref="Net.Forward(System.Collections.Generic.IEnumerable{Mat},
    /// System.Collections.Generic.IEnumerable{string})"/> overload requires the requested
    /// names to match the network's REGISTERED unconnected outputs exactly (native check:
    /// "outnames.size() == noutputs") - and some importers register only one output. The
    /// TFLite importer is the notable case: multi-output TFLite models (e.g. MediaPipe's
    /// palm detector, whose box regressors are "Identity" and anchor scores "Identity_1")
    /// register a single output, so that overload throws for them. This helper instead
    /// requests each named layer with a single-name <see cref="Net.Forward(string)"/>
    /// call. With an unchanged input, OpenCV reuses the layer results already computed by
    /// the first call, so the additional outputs are close to free.
    /// </summary>
    /// <param name="net">The network; its input must already be set via <see cref="Net.SetInput"/>.</param>
    /// <param name="outBlobNames">The names of the layers whose outputs to return.</param>
    /// <returns>
    /// One output <see cref="Mat"/> per name, in the same order. The caller must dispose
    /// each returned Mat.
    /// </returns>
    /// <exception cref="ArgumentNullException">Thrown when <paramref name="net"/> or <paramref name="outBlobNames"/> is null.</exception>
    /// <exception cref="ArgumentException">Thrown when <paramref name="outBlobNames"/> is empty or contains a null/empty name.</exception>
    public static Mat[] ForwardAll(this Net net, params string[] outBlobNames)
    {
        if (net is null)
            throw new ArgumentNullException(nameof(net));
        if (outBlobNames is null)
            throw new ArgumentNullException(nameof(outBlobNames));
        if (outBlobNames.Length == 0)
            throw new ArgumentException("At least one output layer name is required.", nameof(outBlobNames));

        var results = new Mat[outBlobNames.Length];
        try
        {
            for (var i = 0; i < outBlobNames.Length; i++)
            {
                if (string.IsNullOrEmpty(outBlobNames[i]))
                    throw new ArgumentException("Output layer names must be non-empty.", nameof(outBlobNames));
                results[i] = net.Forward(outBlobNames[i]);
            }
        }
        catch
        {
            foreach (var result in results)
                result?.Dispose();
            throw;
        }
        return results;
    }
}
