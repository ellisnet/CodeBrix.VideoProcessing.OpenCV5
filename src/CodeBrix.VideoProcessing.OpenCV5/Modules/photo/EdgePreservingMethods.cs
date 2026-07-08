#pragma warning disable CA1008 // Enums should have zero value

namespace CodeBrix.VideoProcessing.OpenCV5; //was previously: OpenCvSharp;

/// <summary>
/// Edge preserving filters
/// </summary>
public enum EdgePreservingMethods
{
    /// <summary>
    ///Recursive Filtering
    /// </summary>
    RecursFilter = 1,

    /// <summary>
    /// Normalized Convolution Filtering
    /// </summary>
    NormconvFilter = 2
}
