using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace CodeBrix.VideoProcessing.OpenCV5.Internal;
//Added for CodeBrix (not an upstream OpenCvSharp file): diagnostics for native
//  library load failures. The .NET runtime's DllNotFoundException reports one
//  "cannot open shared object file" line per probing attempt, which buries the
//  only line that matters (the OS loader's real error - often a MISSING
//  DEPENDENCY of the found library) in the middle of a wall of misleading
//  file-not-found lines. Build() produces a short message that states the
//  actual failure first.
//
//  Deliberately a standalone class rather than a NativeMethods partial: touching
//  any NativeMethods member runs its static constructor, which itself attempts
//  the native load - this class must be usable when that load fails (and in
//  tests, without any native library present at all).

/// <summary>
/// Builds root-cause-first diagnostics for failures to load the native
/// OpenCvSharpExtern library. See <see cref="Build"/>.
/// </summary>
internal static class NativeLibraryLoadDiagnostics
{
    /// <summary>
    /// The platform-specific file name of the native library:
    /// "OpenCvSharpExtern.dll", "libOpenCvSharpExtern.dylib" or "libOpenCvSharpExtern.so".
    /// </summary>
    internal static string NativeLibraryFileName =>
        RuntimeInformation.IsOSPlatform(OSPlatform.Windows) ? NativeMethods.DllExtern + ".dll"
        : RuntimeInformation.IsOSPlatform(OSPlatform.OSX) ? "lib" + NativeMethods.DllExtern + ".dylib"
        : "lib" + NativeMethods.DllExtern + ".so";

    /// <summary>
    /// The NuGet package that ships the native library for the current OS/architecture
    /// (e.g. "CodeBrix.VideoProcessing.OpenCV5.LinuxArm64.ApacheLicenseForever"), or a
    /// generic placeholder when the platform has no matching package.
    /// </summary>
    internal static string GetRuntimePackageNameForCurrentPlatform()
    {
        var osPart =
            RuntimeInformation.IsOSPlatform(OSPlatform.Windows) ? "Windows"
            : RuntimeInformation.IsOSPlatform(OSPlatform.OSX) ? "MacOS"
            : RuntimeInformation.IsOSPlatform(OSPlatform.Linux) ? "Linux"
            : null;
        var archPart = RuntimeInformation.ProcessArchitecture switch
        {
            Architecture.X64 => "X64",
            Architecture.Arm64 => "Arm64",
            _ => null
        };
        return (osPart is null || archPart is null)
            ? "one of the CodeBrix.VideoProcessing.OpenCV5.{Platform}.ApacheLicenseForever native runtime packages"
            : $"CodeBrix.VideoProcessing.OpenCV5.{osPart}{archPart}.ApacheLicenseForever";
    }

    /// <summary>
    /// The directories the .NET runtime probes for DllImport native libraries
    /// (from the host's NATIVE_DLL_SEARCH_DIRECTORIES property), plus the
    /// application base directory.
    /// </summary>
    internal static IReadOnlyList<string> GetNativeProbingDirectories()
    {
        var dirs = new List<string>();
        if (AppContext.GetData("NATIVE_DLL_SEARCH_DIRECTORIES") is string raw)
        {
            foreach (var dir in raw.Split(Path.PathSeparator, StringSplitOptions.RemoveEmptyEntries))
            {
                if (!dirs.Contains(dir))
                    dirs.Add(dir);
            }
        }
        var baseDir = AppContext.BaseDirectory;
        if (!string.IsNullOrEmpty(baseDir) && !dirs.Contains(baseDir))
            dirs.Add(baseDir);
        return dirs;
    }

    /// <summary>
    /// Builds a short root-cause-first diagnostic for a native library load failure.
    /// Distinguishes the two very different failures the runtime reports identically:
    /// the library file is missing from every probing directory (deployment problem),
    /// versus the file exists but the OS loader rejected it (usually a missing native
    /// dependency, or a CPU-architecture mismatch).
    /// </summary>
    internal static string Build()
    {
        var fileName = NativeLibraryFileName;
        var rid = RuntimeInformation.RuntimeIdentifier;
        var package = GetRuntimePackageNameForCurrentPlatform();
        var probingDirs = GetNativeProbingDirectories();

        var found = new List<string>();
        foreach (var dir in probingDirs)
        {
            try
            {
                var candidate = Path.Combine(dir, fileName);
                if (File.Exists(candidate))
                    found.Add(candidate);
            }
#pragma warning disable CA1031
            catch
#pragma warning restore CA1031
            {
                // An unusable entry in the probing list (bad characters, dead mount,
                // access denied) must not break the diagnostic itself.
            }
        }

        var sb = new StringBuilder();
        sb.AppendLine($"Failed to load the native OpenCvSharpExtern library ({fileName}, RID {rid}).");

        if (found.Count == 0)
        {
            sb.AppendLine("The library file was NOT FOUND in any native library probing directory:");
            foreach (var dir in probingDirs)
                sb.AppendLine("  " + dir);
            sb.AppendLine($"Add a reference to the native runtime package for this platform ({package}),");
            sb.AppendLine($"or place {fileName} in one of the directories above.");
            return sb.ToString().TrimEnd();
        }

        var path = found[0];
        sb.AppendLine("The library file WAS FOUND at:");
        sb.AppendLine("  " + path);
        try
        {
            var handle = NativeLibrary.Load(path);
            NativeLibrary.Free(handle);
            sb.AppendLine("and it loads successfully on its own, so the library and its dependencies look healthy.");
            sb.AppendLine("The runtime's DllImport probing may not include that directory (the inner exception");
            sb.AppendLine($"lists the paths it tried); ship the library via {package}");
            sb.AppendLine("so it lands in a probed location, or pre-load it with NativeLibrary.Load(path).");
        }
        catch (BadImageFormatException)
        {
            sb.AppendLine($"but it is not loadable by this {RuntimeInformation.ProcessArchitecture} process (wrong CPU");
            sb.AppendLine($"architecture or corrupt file). Deploy the native library matching this platform ({package}).");
        }
        catch (DllNotFoundException e)
        {
            sb.AppendLine("but the OS loader FAILED TO LOAD it:");
            foreach (var line in ExtractLoaderErrorLines(e.Message))
                sb.AppendLine("  " + line);
            sb.AppendLine("Because the file exists, the loader error above almost always names a missing");
            sb.AppendLine("NATIVE DEPENDENCY of the OpenCV library rather than the OpenCV library itself.");
            sb.AppendLine(GetDependencyListHint(path));
        }
        return sb.ToString().TrimEnd();
    }

    /// <summary>
    /// Extracts the OS loader's own error lines from a DllNotFoundException message,
    /// dropping the generic "Unable to load shared library ..." header. Falls back to
    /// the first line when the message has no separate detail lines (e.g. on Windows,
    /// where the loader reports a single HRESULT line).
    /// </summary>
    private static IEnumerable<string> ExtractLoaderErrorLines(string message)
    {
        var lines = message.Split('\n');
        var details = new List<string>();
        for (var i = 1; i < lines.Length; i++)
        {
            var trimmed = lines[i].Trim();
            if (trimmed.Length > 0)
                details.Add(trimmed);
        }
        if (details.Count == 0)
            details.Add(lines[0].Trim());
        return details;
    }

    /// <summary>
    /// A per-OS hint for listing the native library's dependencies to find every
    /// missing one (the loader only reports the first).
    /// </summary>
    private static string GetDependencyListHint(string path)
    {
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            return $"Run `dumpbin /dependents \"{path}\"` (or the Dependencies tool) to list them all.";
        if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            return $"Run `otool -L \"{path}\"` to list them all.";
        return $"Run `ldd \"{path}\"` to list them all and see which are missing.";
    }
}
