// ReSharper disable InconsistentNaming

namespace CodeBrix.VideoProcessing.OpenCV5; //was previously: OpenCvSharp;

/// <summary>
/// Bounding box calculation precision used by Volume.GetBoundingBox().
/// </summary>
public enum VolumeBoundingBoxPrecision
{
    /// <summary>
    /// up to volume unit
    /// </summary>
    VOLUME_UNIT = 0,

    /// <summary>
    /// up to voxel (currently not supported)
    /// </summary>
    VOXEL = 1
}
