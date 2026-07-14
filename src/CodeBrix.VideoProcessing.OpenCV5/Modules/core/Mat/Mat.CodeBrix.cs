using System;

namespace CodeBrix.VideoProcessing.OpenCV5;
//Added for CodeBrix (not an upstream OpenCvSharp file): Mat helpers for
//  N-dimensional data access, e.g. DNN output tensors.

public partial class Mat
{
    /// <summary>
    /// Copies this matrix's data - of ANY dimensionality - into a new managed array, in
    /// row-major order. This is the way to read N-dimensional data such as DNN output
    /// tensors, which <see cref="GetArray{T}(out T[])"/> cannot handle (that method sizes
    /// its result from <see cref="Rows"/> x <see cref="Cols"/>, and both report -1 for a
    /// Mat with more than two dimensions).
    /// <para/>
    /// <typeparamref name="T"/> must match the matrix's element layout: either the
    /// per-channel primitive (e.g. <c>float</c> for any CV_32F matrix - a
    /// 1 x 2016 x 18 CV_32FC1 DNN output yields a float[36288]) or a struct covering all
    /// channels of one element (e.g. <c>Vec3f</c> for CV_32FC3).
    /// </summary>
    /// <typeparam name="T">The element type to copy out.</typeparam>
    /// <returns>A new array holding the matrix data; empty when the matrix is empty.</returns>
    /// <exception cref="OpenCvSharpException">
    /// Thrown when the matrix is not continuous, or the size of <typeparamref name="T"/>
    /// matches neither the matrix's per-channel size nor its full element size.
    /// </exception>
    public T[] ToArray<T>()
        where T : unmanaged
    {
        ThrowIfDisposed();

        if (Empty())
            return Array.Empty<T>();
        if (!IsContinuous())
            throw new OpenCvSharpException(
                "Mat.ToArray<T> requires a continuous Mat; call Clone() first for a non-continuous view.");

        var matType = Type();
        var perChannelBytes = ElemSize1();
        var elementBytes = ElemSize();
        long totalBytes = Total() * elementBytes;

        unsafe
        {
            if (sizeof(T) != perChannelBytes && sizeof(T) != elementBytes)
                throw new OpenCvSharpException(
                    $"Type argument {typeof(T)} ({sizeof(T)} bytes) matches neither the per-channel size " +
                    $"({perChannelBytes} bytes) nor the element size ({elementBytes} bytes) of this {matType} Mat.");

            var result = new T[totalBytes / sizeof(T)];
            fixed (T* destination = result)
            {
                Buffer.MemoryCopy((void*)Data, destination, totalBytes, totalBytes);
            }
            return result;
        }
    }
}
