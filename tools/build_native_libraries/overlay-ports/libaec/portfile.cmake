# OVERLAY (CodeBrix, 2026-09-24): identical to the libaec port at the pinned
# vcpkg baseline (pins.env VCPKG_COMMIT) EXCEPT the source download. The
# baseline port fetches GitLab's generated archive
# (https://gitlab.dkrz.de/k202009/libaec/-/archive/v1.1.6/...), and that
# endpoint answered every anonymous request with HTTP 429 from multiple
# networks, which halted the osx-x64 build. The same tag is fetched here over
# git instead, pinned to its commit (content-addressed, so the source is exactly
# as fixed as with the archive's SHA512). The project moved from k202009/libaec
# to dkrz-sw/libaec; the old path still redirects.
vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://gitlab.dkrz.de/dkrz-sw/libaec.git
    REF 50b1537986a7394d5079ec427295614179d3eed6
    FETCH_REF "v${VERSION}"
)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" BUILD_STATIC)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_STATIC_LIBS=${BUILD_STATIC}
        -Dlibaec_INSTALL_CMAKEDIR=share/${PORT}
)
vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_cmake_config_fixup()
vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/libaec/libaec-config.cmake"
    "if(libaec_USE_STATIC_LIBS)"
    "if(\"${BUILD_STATIC}\") # forced by vcpkg"
)

# Compatibility with user's CMake < 3.18 (vcpkg claims support for >= 3.16):
# Make imported targets global so that libaec-config.cmake can create ALIAS targets.
set(_target_file "libaec_shared-targets")
if(BUILD_STATIC)
    set(_target_file "libaec_static-targets")
endif()
file(READ "${CURRENT_PACKAGES_DIR}/share/libaec/${_target_file}.cmake" libaec_targets)
string(REGEX REPLACE " (SHARED|STATIC) IMPORTED" " \\1 IMPORTED \${libaec_maybe_global}" libaec_targets "${libaec_targets}")
file(WRITE "${CURRENT_PACKAGES_DIR}/share/libaec/${_target_file}.cmake" "set(libaec_maybe_global \"\")
if(CMAKE_VERSION VERSION_LESS 3.18)
    set(libaec_maybe_global \"GLOBAL\")
endif()
${libaec_targets}
"
)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${CURRENT_PORT_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
