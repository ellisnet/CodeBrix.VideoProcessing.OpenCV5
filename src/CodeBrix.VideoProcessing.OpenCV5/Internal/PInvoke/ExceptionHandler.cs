using System;

namespace CodeBrix.VideoProcessing.OpenCV5.Internal; //was previously: OpenCvSharp.Internal;

/// <summary>
/// Surfaces the last native OpenCV exception as a managed exception.
/// </summary>
/// <remarks>
/// Details are captured natively, on the calling thread, directly from the thrown C++
/// exception (see the native cvTry / LastNativeException). No managed error callback is
/// installed in the default path, so this is NativeAOT / trimming friendly.
/// </remarks>
public static class ExceptionHandler
{
    //A background thread that calls into native OpenCV as the process shuts down can reach
    //  the runtime after its per-thread (TLS) state has been torn down; OpenCV then aborts
    //  the call ("Can't fetch data from terminated TLS container", and similar teardown
    //  failures). It is a routine hazard for the very common pattern of running video
    //  processing on a worker thread, and there is nothing to recover - so this flag lets
    //  ThrowPossibleException swallow such post-shutdown failures rather than let an orderly
    //  exit become a fatal unhandled exception on that thread. Set once, never cleared.
    private static volatile bool _processShuttingDown;

    static ExceptionHandler()
    {
        AppDomain domain = AppDomain.CurrentDomain;
        domain.ProcessExit += (_, _) => _processShuttingDown = true;
        domain.DomainUnload += (_, _) => _processShuttingDown = true;
    }

    /// <summary>
    /// Throws an <see cref="OpenCVException"/> built from the per-thread native exception
    /// record. Call only when an export reported <see cref="ExceptionStatus.Occurred"/>.
    /// </summary>
    /// <remarks>
    /// If the process has begun shutting down, a native failure caused by the runtime being
    /// torn down under a still-running background thread is swallowed instead of thrown -
    /// there is no recovery at that point and the result is discarded, so surfacing it would
    /// only turn an orderly exit into a fatal unhandled exception.
    /// </remarks>
    public static void ThrowPossibleException()
    {
        using var func = new StdString();
        using var file = new StdString();
        using var message = new StdString();

        NativeMethods.core_getLastException(out var code, out var line, func.CvPtr, file.CvPtr, message.CvPtr);

        var messageText = message.ToString();

        //Swallow post-shutdown teardown failures. Match both the shutdown signals and the
        //  specific native assertion, which is emitted only in this teardown case and so
        //  also covers the brief window before those signals flip.
        if (_processShuttingDown
            || Environment.HasShutdownStarted
            || messageText.Contains("terminated TLS container", StringComparison.Ordinal))
        {
            return;
        }

        throw new OpenCVException((ErrorCode)code, func.ToString(), messageText, file.ToString(), line);
    }
}
