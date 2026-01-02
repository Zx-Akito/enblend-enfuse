#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "TIFF::tiff" for configuration ""
set_property(TARGET TIFF::tiff APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(TIFF::tiff PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libtiff.6.2.0.dylib"
  IMPORTED_SONAME_NOCONFIG "@rpath/libtiff.6.dylib"
  )

list(APPEND _cmake_import_check_targets TIFF::tiff )
list(APPEND _cmake_import_check_files_for_TIFF::tiff "${_IMPORT_PREFIX}/lib/libtiff.6.2.0.dylib" )

# Import target "TIFF::tiffxx" for configuration ""
set_property(TARGET TIFF::tiffxx APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(TIFF::tiffxx PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libtiffxx.6.2.0.dylib"
  IMPORTED_SONAME_NOCONFIG "@rpath/libtiffxx.6.dylib"
  )

list(APPEND _cmake_import_check_targets TIFF::tiffxx )
list(APPEND _cmake_import_check_files_for_TIFF::tiffxx "${_IMPORT_PREFIX}/lib/libtiffxx.6.2.0.dylib" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
