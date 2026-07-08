================================================================================
native_libraries/ — vendored native binaries (xz-compressed)
================================================================================

The *.xz files under runtimes/ are the EXACT native binaries published by the
upstream OpenCvSharp project on NuGet (OpenCvSharp5 runtime packages,
5.0.0.20260703; osx packages 5.0.0.20260704), captured once on 2026-07-07 and
never re-fetched. Each file sits at its exact shipped nupkg path plus an .xz
suffix (e.g. runtimes/linux-x64/native/libOpenCvSharpExtern.so.xz), so the
runtime-package nuspec mappings are 1:1 and a future self-built-natives
switch is drop-in (build sources: ../native_src/).

SHA256SUMS.txt records the SHA-256 of every RAW (uncompressed) binary. The
pack driver's MaterializeNatives target decompresses in place (xz -dkf) and
verifies these hashes before any package is produced, failing loudly on
mismatch.

NEVER commit the raw .so/.dll/.dylib files — the linux-x64 .so (131 MB) and
osx-x64 .dylib (127 MB) exceed GitHub's 100 MiB hard blob limit, which
applies anywhere in history. The repo .gitignore blocks them; leave it be.

To materialize manually (e.g. before running the native-dependent tests):

    cd native_libraries
    find . -name '*.xz' -exec xz -dkf {} +
    sha256sum -c SHA256SUMS.txt

License/attribution: THIRD-PARTY-NOTICES.txt item 2 at the repo root.
================================================================================
