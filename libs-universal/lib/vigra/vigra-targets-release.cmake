#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "vigraimpex" for configuration "Release"
set_property(TARGET vigraimpex APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vigraimpex PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvigraimpex.11.1.12.3.dylib"
  IMPORTED_SONAME_RELEASE "/Users/zxakito/Downloads/vigra-install-universal/lib/libvigraimpex.11.dylib"
  )

list(APPEND _cmake_import_check_targets vigraimpex )
list(APPEND _cmake_import_check_files_for_vigraimpex "${_IMPORT_PREFIX}/lib/libvigraimpex.11.1.12.3.dylib" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
