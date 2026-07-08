// ReSharper disable InconsistentNaming

namespace CodeBrix.VideoProcessing.OpenCV5; //was previously: OpenCvSharp;

/// <summary>
/// These constants are used to set the speed and accuracy of odometry.
/// </summary>
public enum OdometryAlgoType
{
    /// <summary>
    /// accurate but not so fast
    /// </summary>
    COMMON = 0,

    /// <summary>
    /// less accurate but faster
    /// </summary>
    FAST = 1
}
