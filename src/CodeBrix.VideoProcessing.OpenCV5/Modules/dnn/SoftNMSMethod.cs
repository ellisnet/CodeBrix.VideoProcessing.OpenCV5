#pragma warning disable CS1591

// ReSharper disable IdentifierTypo
// ReSharper disable InconsistentNaming

namespace CodeBrix.VideoProcessing.OpenCV5.Dnn; //was previously: OpenCvSharp.Dnn;

/// <summary>
/// Enum of Soft NMS methods.
/// </summary>
public enum SoftNMSMethod
{
    SOFTNMS_LINEAR = 1,
    SOFTNMS_GAUSSIAN = 2,
}
