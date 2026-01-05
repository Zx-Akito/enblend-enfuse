# This file is part of enblend/enfuse.
# Licence details can be found in the file COPYING.
#
# Copyright (c) 2009-2015, Kornel Benko <Kornel.Benko@berlin.de>
#                   , Ryan Sleevi <ryan+hugin@sleevi.com>
#                   , Harry van der Wolf <hvdwolf@gmail.com>
#

# Get the version-string from ${TOP_SRC_DIR}/VERSION

add_custom_command(
  OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/signature.h"
  COMMAND ${PERL_EXECUTABLE} -I"${TOP_SRC_DIR}/src" "${TOP_SRC_DIR}/src/gen_sig"
  "--extra=${ENBLEND_MAJOR_VERSION}.${ENBLEND_MINOR_VERSION}-${ENBLEND_CHANGESET}"
  ">" "${CMAKE_CURRENT_BINARY_DIR}/signature.h"
  DEPENDS "${TOP_SRC_DIR}/src/gen_sig" "${TOP_SRC_DIR}/VERSION"
  )
add_custom_target(signature DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/signature.h")

IF(ENABLE_OPENCL)
  # prepare all OpenCL sources
  SET(OPENCL_SOURCES)
  FILE(GLOB opencl_sources ${TOP_SRC_DIR}/src/*.cl)
  IF(PREFER_SEPARATE_OPENCL_SOURCE)
    INSTALL(FILES ${opencl_sources} DESTINATION ${CMAKE_INSTALL_PREFIX}/share/enblend/kernels)
  ELSE()
    FILE(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/kernels")
    FOREACH(_cl_source ${opencl_sources})
      GET_FILENAME_COMPONENT(_cl_filename "${_cl_source}" NAME)

      STRING(REGEX REPLACE "[.]cl$" ".icl" _icl_source "${_cl_filename}")
      SET(_icl_source "${CMAKE_CURRENT_BINARY_DIR}/kernels/${_icl_source}")
      STRING(REGEX REPLACE "[.]cl$" "_source_code" _cl_label "${_cl_filename}")

      ADD_CUSTOM_COMMAND(
        OUTPUT "${_icl_source}"
        COMMAND ${PERL_EXECUTABLE} "${TOP_SRC_DIR}/src/embrace"
          "--format=c++" "--label=${_cl_label}" "${_cl_source}" ">" "${_icl_source}"
        DEPENDS "${_cl_source}"
        COMMENT "Generating ${_icl_source}"
      )
      SET_SOURCE_FILES_PROPERTIES("${_icl_source}" GENERATED)
      LIST(APPEND OPENCL_SOURCES "${_icl_source}")
    ENDFOREACH()

    ADD_CUSTOM_TARGET(cl_sources ALL DEPENDS ${OPENCL_SOURCES})
    INCLUDE_DIRECTORIES("${CMAKE_CURRENT_BINARY_DIR}/kernels")
  ENDIF()
ENDIF()

include_directories(${TOP_SRC_DIR}/src)
set(ENBLEND_SOURCES 
    fillpolygon.hxx functoraccessor.hxx rect2d.hxx stride.hxx
    allocate.h 
    anneal.h assemble.h blend.h bounds.h
    common.h enblend.h enblend.cc fixmath.h
    global.h graphcut.h
    maskcommon.h masktypedefs.h mask.h postoptimizer.h
    nearest.h numerictraits.h
    opencl.h opencl.cc opencl_vigra.h
    openmp_def.h openmp_lock.h openmp_vigra.h
    path.h pyramid.h
    alternativepercentage.h alternativepercentage.cc
    error_message.h error_message.cc
    filenameparse.h filenameparse.cc
    filespec.h filespec.cc
    introspection.h introspection.cc
    mersenne.h mersenne.cc
    metadata.h metadata.cc
    parameter.h parameter.cc
    self_test.h self_test.cc
    tiff_message.h tiff_message.cc
    timer.h timer.cc
    minimizer.h minimizer.cc
    muopt.h
    optional_transitional.hpp
)
set(ENFUSE_SOURCES 
    functoraccessor.hxx rect2d.hxx stride.hxx
    allocate.h
    assemble.h blend.h bounds.h common.h
    exposure_weight_base.h
    exposure_weight.h exposure_weight.cc
    enfuse.h enfuse.cc fixmath.h
    global.h mga.h numerictraits.h
    opencl.h opencl.cc opencl_vigra.h
    opencl_exposure_weight.h opencl_exposure_weight.cc
    openmp_def.h openmp_lock.h openmp_vigra.h
    pyramid.h
    alternativepercentage.h alternativepercentage.cc
    error_message.h error_message.cc
    filenameparse.h filenameparse.cc
    filespec.h filespec.cc
    introspection.h introspection.cc
    mersenne.h mersenne.cc
    metadata.h metadata.cc
    parameter.h parameter.cc
    self_test.h self_test.cc
    tiff_message.h tiff_message.cc
    timer.h timer.cc
    minimizer.h minimizer.cc
    muopt.h
    optional_transitional.hpp
)

set(additional_libs)
if (WIN32)
  list(APPEND ENBLEND_SOURCES win32helpers/delayHelper.h)
  list(APPEND ENFUSE_SOURCES win32helpers/delayHelper.h)
  add_subdirectory(win32helpers)
  list(APPEND additional_libs getopt)
endif()

add_subdirectory(layer_selection)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/layer_selection)
list(APPEND additional_libs layer_selection)

add_subdirectory(dynamic_loader)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/dynamic_loader)
add_definitions(${DL_DEFINITION})
list(APPEND additional_libs dynamic_loader)

include_directories(${CMAKE_CURRENT_BINARY_DIR})

message(STATUS "Boost_FOUND = ${Boost_FOUND}")
message(STATUS "OpenMP_CXX_FLAGS = ${OpenMP_CXX_FLAGS}")

add_executable(enblend ${ENBLEND_SOURCES})
add_executable(enfuse ${ENFUSE_SOURCES})

add_dependencies(enblend signature)
add_dependencies(enfuse signature)
target_compile_definitions(enblend PUBLIC "-DENBLEND_SOURCE")
target_compile_definitions(enfuse PUBLIC "-DENFUSE_SOURCE")
if(OpenMP_CXX_FLAGS AND NOT MSVC)
    set_target_properties(enblend PROPERTIES LINK_FLAGS ${OpenMP_CXX_FLAGS})
    set_target_properties(enfuse PROPERTIES LINK_FLAGS ${OpenMP_CXX_FLAGS})
    message(STATUS "Adding PROPERTIES LINK_FLAGS to enblend and enfuse")
endif(OpenMP_CXX_FLAGS AND NOT MSVC)
target_link_libraries(enblend ${common_libs} ${additional_libs})
target_link_libraries(enfuse ${common_libs} ${additional_libs})

# Set rpath for macOS to find libraries in Frameworks directory
if(APPLE)
    set_target_properties(enblend PROPERTIES
        INSTALL_RPATH "@executable_path/lib"
        BUILD_WITH_INSTALL_RPATH TRUE
    )
    set_target_properties(enfuse PROPERTIES
        INSTALL_RPATH "@executable_path/lib"
        BUILD_WITH_INSTALL_RPATH TRUE
    )
    # Also add rpath at build time
    set_target_properties(enblend PROPERTIES
        BUILD_RPATH "@executable_path/lib"
    )
    set_target_properties(enfuse PROPERTIES
        BUILD_RPATH "@executable_path/lib"
    )
endif()

if(ENABLE_OPENCL AND MSVC)
  # provide delay loading of opencl.dll
  set_target_properties(enblend PROPERTIES LINK_FLAGS "/DELAYLOAD:opencl.dll")
  set_target_properties(enfuse PROPERTIES LINK_FLAGS "/DELAYLOAD:opencl.dll")
endif()
install(TARGETS enblend enfuse DESTINATION bin CONFIGURATIONS Release RelWithDebInfo MinSizeRel)

IF(ENABLE_OPENCL AND NOT ${PREFER_SEPARATE_OPENCL_SOURCE})
    add_dependencies(enblend cl_sources)
    add_dependencies(enfuse cl_sources)
ENDIF()

# macOS: Copy libraries to Frameworks and fix install_name
if(APPLE)
    set(FRAMEWORKS_DIR "${CMAKE_BINARY_DIR}/bin/lib")
    
    # Create Frameworks directory
    file(MAKE_DIRECTORY ${FRAMEWORKS_DIR})
    
    # Function to process a library: copy to Frameworks and fix install_name
    function(fix_library_for_target target lib_path)
        if(lib_path AND EXISTS ${lib_path})
            get_filename_component(lib_name ${lib_path} NAME)
            get_filename_component(lib_abs_path ${lib_path} ABSOLUTE)
            
            # Get install_name from library at configure time using a helper script
            set(GET_INSTALL_NAME_HELPER "${CMAKE_BINARY_DIR}/get_install_name_helper.sh")
            file(WRITE ${GET_INSTALL_NAME_HELPER}
                "#!/bin/bash\n"
                "otool -L \"$1\" | grep -m1 \"^\\t\" | sed 's/^[[:space:]]*//' | cut -d' ' -f1\n"
            )
            file(COPY ${GET_INSTALL_NAME_HELPER} DESTINATION ${CMAKE_BINARY_DIR} FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
            
            execute_process(
                COMMAND bash ${GET_INSTALL_NAME_HELPER} ${lib_abs_path}
                OUTPUT_VARIABLE old_install_name
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
            )
            if(NOT old_install_name)
                set(old_install_name ${lib_abs_path})
            endif()
            
            # Extract the actual library name from install_name (e.g., liblcms2.2.dylib from /path/to/liblcms2.2.dylib)
            get_filename_component(actual_lib_name ${old_install_name} NAME)
            
            # Copy library to Frameworks using the actual library name
            add_custom_command(TARGET ${target} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different ${lib_abs_path} ${FRAMEWORKS_DIR}/${actual_lib_name}
                COMMENT "Copying ${actual_lib_name} to Frameworks"
            )
            
            # Fix install_name in the copied library
            add_custom_command(TARGET ${target} POST_BUILD
                COMMAND install_name_tool -id "@rpath/${actual_lib_name}" ${FRAMEWORKS_DIR}/${actual_lib_name}
                COMMENT "Fixing install_name for ${actual_lib_name}"
            )
            
            # Fix install_name in binary to use @rpath
            # Create a script to safely change install_name
            set(FIX_BINARY_SCRIPT "${CMAKE_BINARY_DIR}/fix_binary_${target}_${lib_name}.sh")
            file(WRITE ${FIX_BINARY_SCRIPT}
                "#!/bin/bash\n"
                "BINARY=\"$1\"\n"
                "OLD_PATH=\"${old_install_name}\"\n"
                "NEW_PATH=\"@rpath/${actual_lib_name}\"\n"
                "LIB_ABS=\"${lib_abs_path}\"\n"
                "# Try to change using old_install_name first\n"
                "if otool -L \"$BINARY\" | grep -q \"$OLD_PATH\"; then\n"
                "    install_name_tool -change \"$OLD_PATH\" \"$NEW_PATH\" \"$BINARY\" 2>/dev/null || true\n"
                "elif otool -L \"$BINARY\" | grep -q \"$LIB_ABS\"; then\n"
                "    install_name_tool -change \"$LIB_ABS\" \"$NEW_PATH\" \"$BINARY\" 2>/dev/null || true\n"
                "fi\n"
            )
            file(COPY ${FIX_BINARY_SCRIPT} DESTINATION ${CMAKE_BINARY_DIR} FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
            
            add_custom_command(TARGET ${target} POST_BUILD
                COMMAND bash ${FIX_BINARY_SCRIPT} $<TARGET_FILE:${target}>
                COMMENT "Updating ${target} to use @rpath for ${lib_name}"
            )
        endif()
    endfunction()
    
    # Process LCMS2 library
    if(LCMS2_LIBRARIES)
        foreach(lib ${LCMS2_LIBRARIES})
            fix_library_for_target(enblend ${lib})
            fix_library_for_target(enfuse ${lib})
        endforeach()
    endif()
    
    # Process TIFF library
    if(TIFF_LIBRARIES)
        foreach(lib ${TIFF_LIBRARIES})
            fix_library_for_target(enblend ${lib})
            fix_library_for_target(enfuse ${lib})
        endforeach()
    endif()
    
    # Process GSL libraries
    if(GSL_LIBRARIES)
        foreach(lib ${GSL_LIBRARIES})
            fix_library_for_target(enblend ${lib})
            fix_library_for_target(enfuse ${lib})
        endforeach()
    endif()
    
    # Process VIGRA library
    if(VIGRA_LIBRARIES)
        foreach(vigra_lib ${VIGRA_LIBRARIES})
            if(vigra_lib MATCHES "\\.dylib$")
                fix_library_for_target(enblend ${vigra_lib})
                fix_library_for_target(enfuse ${vigra_lib})
            endif()
        endforeach()
    endif()
    
    # Process JPEG library if found
    if(JPEG_LIBRARIES)
        foreach(lib ${JPEG_LIBRARIES})
            if(lib MATCHES "\\.dylib$")
                fix_library_for_target(enblend ${lib})
                fix_library_for_target(enfuse ${lib})
            endif()
        endforeach()
    endif()
    
    # Process PNG library if found
    if(PNG_LIBRARIES)
        foreach(lib ${PNG_LIBRARIES})
            if(lib MATCHES "\\.dylib$")
                fix_library_for_target(enblend ${lib})
                fix_library_for_target(enfuse ${lib})
            elseif(lib MATCHES "\\.framework$")
                # Handle framework - copy binary directly to Frameworks (no framework structure)
                get_filename_component(framework_name ${lib} NAME)
                get_filename_component(framework_abs_path ${lib} ABSOLUTE)
                
                # Extract base name from framework (e.g., "png" from "png.framework")
                string(REGEX REPLACE "\\.framework$" "" base_name ${framework_name})
                
                # Create script to copy framework binary directly to Frameworks
                set(COPY_FRAMEWORK_SCRIPT "${CMAKE_BINARY_DIR}/copy_framework_${framework_name}.sh")
                file(WRITE ${COPY_FRAMEWORK_SCRIPT}
                    "#!/bin/bash\n"
                    "FRAMEWORK_SRC=\"${framework_abs_path}\"\n"
                    "FRAMEWORKS_DIR=\"${FRAMEWORKS_DIR}\"\n"
                    "BINARY_NAME=\"${base_name}\"\n"
                    "# Find framework binary\n"
                    "if [ -f \"$FRAMEWORK_SRC/Versions/1.8.0/$BINARY_NAME\" ]; then\n"
                    "    BINARY_PATH=\"$FRAMEWORK_SRC/Versions/1.8.0/$BINARY_NAME\"\n"
                    "elif [ -L \"$FRAMEWORK_SRC/Versions/Current\" ]; then\n"
                    "    VERSION=$(readlink \"$FRAMEWORK_SRC/Versions/Current\")\n"
                    "    BINARY_PATH=\"$FRAMEWORK_SRC/Versions/$VERSION/$BINARY_NAME\"\n"
                    "elif [ -f \"$FRAMEWORK_SRC/$BINARY_NAME\" ]; then\n"
                    "    BINARY_PATH=\"$FRAMEWORK_SRC/$BINARY_NAME\"\n"
                    "else\n"
                    "    exit 1\n"
                    "fi\n"
                    "# Copy binary directly to Frameworks (no framework structure)\n"
                    "cp -f \"$BINARY_PATH\" \"$FRAMEWORKS_DIR/$BINARY_NAME\"\n"
                    "# Fix install_name to use @rpath directly\n"
                    "install_name_tool -id \"@rpath/$BINARY_NAME\" \"$FRAMEWORKS_DIR/$BINARY_NAME\" 2>/dev/null || true\n"
                )
                file(COPY ${COPY_FRAMEWORK_SCRIPT} DESTINATION ${CMAKE_BINARY_DIR} FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
                
                # Create script to fix binary references from framework path to direct path
                set(FIX_PNG_REF_SCRIPT "${CMAKE_BINARY_DIR}/fix_png_ref.sh")
                file(WRITE ${FIX_PNG_REF_SCRIPT}
                    "#!/bin/bash\n"
                    "BINARY=\"$1\"\n"
                    "# Change reference from @rpath/png.framework/Versions/1.8.0/png to @rpath/png\n"
                    "install_name_tool -change \"@rpath/png.framework/Versions/1.8.0/png\" \"@rpath/png\" \"$BINARY\" 2>/dev/null || true\n"
                    "install_name_tool -change \"@rpath/png.framework/Versions/Current/png\" \"@rpath/png\" \"$BINARY\" 2>/dev/null || true\n"
                    "# Try any version path\n"
                    "for version in 1.8.0 A Current; do\n"
                    "    install_name_tool -change \"@rpath/png.framework/Versions/$version/png\" \"@rpath/png\" \"$BINARY\" 2>/dev/null || true\n"
                    "done\n"
                )
                file(COPY ${FIX_PNG_REF_SCRIPT} DESTINATION ${CMAKE_BINARY_DIR} FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
                
                # Add commands for both targets
                add_custom_command(TARGET enblend POST_BUILD
                    COMMAND bash ${COPY_FRAMEWORK_SCRIPT}
                    COMMENT "Copying ${base_name} binary directly to Frameworks"
                )
                add_custom_command(TARGET enblend POST_BUILD
                    COMMAND bash ${FIX_PNG_REF_SCRIPT} $<TARGET_FILE:enblend>
                    COMMENT "Fixing enblend to use @rpath/png instead of framework path"
                )
                add_custom_command(TARGET enfuse POST_BUILD
                    COMMAND bash ${COPY_FRAMEWORK_SCRIPT}
                    COMMENT "Copying ${base_name} binary directly to Frameworks"
                )
                add_custom_command(TARGET enfuse POST_BUILD
                    COMMAND bash ${FIX_PNG_REF_SCRIPT} $<TARGET_FILE:enfuse>
                    COMMENT "Fixing enfuse to use @rpath/png instead of framework path"
                )
            endif()
        endforeach()
    endif()
    
    # Fix any existing libraries in Frameworks directory
    # Create a script to fix all libraries
    set(FIX_FRAMEWORKS_SCRIPT "${CMAKE_BINARY_DIR}/fix_frameworks.sh")
    file(WRITE ${FIX_FRAMEWORKS_SCRIPT}
        "#!/bin/bash\n"
        "FRAMEWORKS_DIR=\"${FRAMEWORKS_DIR}\"\n"
        "for lib in \"${FRAMEWORKS_DIR}\"/*.dylib \"${FRAMEWORKS_DIR}\"/png; do\n"
        "    if [ -f \"$lib\" ]; then\n"
        "        libname=$(basename \"$lib\")\n"
        "        install_name_tool -id \"@rpath/$libname\" \"$lib\" 2>/dev/null || true\n"
        "        # Fix png framework references to direct png\n"
        "        for version in 1.8.0 A Current; do\n"
        "            install_name_tool -change \"@rpath/png.framework/Versions/$version/png\" \"@rpath/png\" \"$lib\" 2>/dev/null || true\n"
        "        done\n"
        "    fi\n"
        "done\n"
    )
    file(COPY ${FIX_FRAMEWORKS_SCRIPT} DESTINATION ${CMAKE_BINARY_DIR} FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    
    add_custom_command(TARGET enblend POST_BUILD
        COMMAND bash ${FIX_FRAMEWORKS_SCRIPT}
        COMMENT "Fixing install_name for existing libraries in Frameworks"
    )
    add_custom_command(TARGET enfuse POST_BUILD
        COMMAND bash ${FIX_FRAMEWORKS_SCRIPT}
        COMMENT "Fixing install_name for existing libraries in Frameworks"
    )
    
    # Add rpath to binaries using install_name_tool
    # Check if rpath already exists before adding
    set(ADD_RPATH_SCRIPT "${CMAKE_BINARY_DIR}/add_rpath.sh")
    file(WRITE ${ADD_RPATH_SCRIPT}
        "#!/bin/bash\n"
        "BINARY=\"$1\"\n"
        "RPATH=\"@executable_path/lib\"\n"
        "if ! otool -l \"$BINARY\" | grep -q \"$RPATH\"; then\n"
        "    install_name_tool -add_rpath \"$RPATH\" \"$BINARY\" 2>/dev/null || true\n"
        "fi\n"
    )
    file(COPY ${ADD_RPATH_SCRIPT} DESTINATION ${CMAKE_BINARY_DIR} FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    
    add_custom_command(TARGET enblend POST_BUILD
        COMMAND bash ${ADD_RPATH_SCRIPT} $<TARGET_FILE:enblend>
        COMMENT "Adding rpath to enblend"
    )
    add_custom_command(TARGET enfuse POST_BUILD
        COMMAND bash ${ADD_RPATH_SCRIPT} $<TARGET_FILE:enfuse>
        COMMENT "Adding rpath to enfuse"
    )
endif()

if(NOT WIN32)
    # create enblend.1 and enfuse.1
    if(NOT MANDIR AND NOT $ENV{MANDIR} STREQUAL "")
        set(MANDIR "$ENV{MANDIR}")
    elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD" OR CMAKE_SYSTEM_NAME STREQUAL "NetBSD")
        set(MANDIR "man")
    else(NOT MANDIR AND NOT $ENV{MANDIR} STREQUAL "")
        set(MANDIR "share/man")
    endif()
    
    find_program(HELP2MAN_EXE "help2man")
    if (NOT DOC OR ${HELP2MAN_EXE} MATCHES "-NOTFOUND")
        INSTALL(FILES enblend.1 enfuse.1 DESTINATION ${MANDIR}/man1)
    else()
        project(man)
        add_custom_command(
          OUTPUT "${CMAKE_BINARY_DIR}/src/enblend.1"
          COMMAND "${HELP2MAN_EXE}" "--output=enblend.1" "${CMAKE_BINARY_DIR}/bin/enblend"
          DEPENDS "${CMAKE_BINARY_DIR}/bin/enblend"
          )
        add_custom_command(
          OUTPUT "${CMAKE_BINARY_DIR}/src/enfuse.1"
          COMMAND "${HELP2MAN_EXE}" "--output=enfuse.1" "${CMAKE_BINARY_DIR}/bin/enfuse"
          DEPENDS "${CMAKE_BINARY_DIR}/bin/enfuse"
          )
        add_custom_target(man ALL DEPENDS enblend.1 enfuse.1)
        add_dependencies(man enblend enfuse)
        INSTALL(FILES ${CMAKE_BINARY_DIR}/src/enblend.1 ${CMAKE_BINARY_DIR}/src/enfuse.1 DESTINATION ${MANDIR}/man1)
    endif()
endif()
