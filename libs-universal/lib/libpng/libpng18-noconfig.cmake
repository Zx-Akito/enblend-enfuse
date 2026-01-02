#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "png_shared" for configuration ""
set_property(TARGET png_shared APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(png_shared PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libpng18.18.0.git.dylib"
  IMPORTED_SONAME_NOCONFIG "@rpath/libpng18.18.dylib"
  )

list(APPEND _cmake_import_check_targets png_shared )
list(APPEND _cmake_import_check_files_for_png_shared "${_IMPORT_PREFIX}/lib/libpng18.18.0.git.dylib" )

# Import target "png_framework" for configuration ""
set_property(TARGET png_framework APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(png_framework PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/png.framework/Versions/1.8.0/png"
  IMPORTED_SONAME_NOCONFIG "@rpath/png.framework/Versions/1.8.0/png"
  )

list(APPEND _cmake_import_check_targets png_framework )
list(APPEND _cmake_import_check_files_for_png_framework "${_IMPORT_PREFIX}/lib/png.framework/Versions/1.8.0/png" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
