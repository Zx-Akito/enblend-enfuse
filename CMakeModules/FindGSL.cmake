# Script copied from http://www.cmake.org/pipermail/cmake/attachments/20080709/38127d1f/attachment.obj
# and modified for use in enblend
# (replaced calls like: 
#      SET(GSL_LIBRARIES "`${GSL_CONFIG} --libs`")
#  with:
#      EXEC_PROGRAM(${GSL_CONFIG} ARGS "--libs" OUTPUT_VARIABLE GSL_LIBRARIES)
# )
###################
# Script found on KDE-edu list
# TODO replace this with OpenCog SIAI copyrighted version.
# 
# Look for the header file
# Try to find gnu scientific library GSL
# See 
# http://www.gnu.org/software/gsl/  and 
# http://gnuwin32.sourceforge.net/packages/gsl.htm
#
# Once run this will define: 
# 
# GSL_FOUND       = system has GSL lib
#
# GSL_LIBRARIES   = full path to the libraries
#    on Unix/Linux with additional linker flags from "gsl-config --libs"
# 
# CMAKE_GSL_CXX_FLAGS  = Unix compiler flags for GSL, essentially "`gsl-config --cxxflags`"
#
# GSL_INCLUDE_DIR      = where to find headers 
#
# GSL_LINK_DIRECTORIES = link directories, useful for rpath on Unix
# GSL_EXE_LINKER_FLAGS = rpath on Unix
#
# Felix Woelk 07/2004
# Jan Woetzel
#
# www.mip.informatik.uni-kiel.de
# --------------------------------

IF(WIN32)
  SET(GSL_POSSIBLE_ROOT_DIRS
    ${SOURCE_BASE_DIR}/gsl
    ${SOURCE_BASE_DIR}/gsl-1.17
    ${SOURCE_BASE_DIR}/gsl-1.16
    ${SOURCE_BASE_DIR}/gsl-1.15
  )
  FIND_PATH(GSL_INCLUDE_DIR
    NAMES gsl/gsl_cdf.h gsl/gsl_randist.h
    PATHS ${GSL_POSSIBLE_ROOT_DIRS}
    PATH_SUFFIXES include
    DOC "GSL header include dir"
    )
  
  include(FindLibraryWithDebug)
  find_library_with_debug(GSL_GSL_LIBRARY
    WIN32_DEBUG_POSTFIX d    
    NAMES gsl libgsl
    PATHS  ${GSL_POSSIBLE_ROOT_DIRS}
    PATH_SUFFIXES lib
    DOC "GSL library dir" )  
  
  find_library_with_debug(GSL_GSLCBLAS_LIBRARY
    WIN32_DEBUG_POSTFIX d    
    NAMES gslcblas libgslcblas cblas
    PATHS  ${GSL_POSSIBLE_ROOT_DIRS}
    PATH_SUFFIXES lib
    DOC "GSL cblas library dir" )
  
  SET(GSL_LIBRARIES ${GSL_GSL_LIBRARY} ${GSL_GSLCBLAS_LIBRARY})

  #MESSAGE("DBG\n"
  #  "GSL_GSL_LIBRARY=${GSL_GSL_LIBRARY}\n"
  #  "GSL_GSLCBLAS_LIBRARY=${GSL_GSLCBLAS_LIBRARY}\n"
  #  "GSL_LIBRARIES=${GSL_LIBRARIES}")

  INCLUDE(FindPackageHandleStandardArgs)
  FIND_PACKAGE_HANDLE_STANDARD_ARGS(GSL DEFAULT_MSG GSL_INCLUDE_DIR GSL_GSL_LIBRARY GSL_GSLCBLAS_LIBRARY)

ELSE(WIN32)
  
  IF(UNIX) 
    # First, try to find GSL manually in CMAKE_PREFIX_PATH (for universal builds)
    # This takes precedence over gsl-config to ensure we use the correct architecture
    # Also check CMAKE_LIBRARY_PATH and CMAKE_INCLUDE_PATH
    SET(GSL_SEARCH_PATHS ${CMAKE_PREFIX_PATH})
    IF(CMAKE_LIBRARY_PATH)
      LIST(APPEND GSL_SEARCH_PATHS ${CMAKE_LIBRARY_PATH})
    ENDIF()
    IF(CMAKE_INCLUDE_PATH)
      LIST(APPEND GSL_SEARCH_PATHS ${CMAKE_INCLUDE_PATH})
    ENDIF()
    
    IF(GSL_SEARCH_PATHS)
      MESSAGE(STATUS "Searching for GSL in: ${GSL_SEARCH_PATHS}")
      FIND_PATH(GSL_INCLUDE_DIR_MANUAL
        NAMES gsl/gsl_cdf.h gsl/gsl_randist.h
        PATHS ${GSL_SEARCH_PATHS}
        PATH_SUFFIXES include
        NO_DEFAULT_PATH
        DOC "GSL header include dir"
      )
      
      IF(GSL_INCLUDE_DIR_MANUAL)
        MESSAGE(STATUS "Found GSL headers at: ${GSL_INCLUDE_DIR_MANUAL}")
        FIND_LIBRARY(GSL_GSL_LIBRARY_MANUAL
          NAMES gsl libgsl
          PATHS ${GSL_SEARCH_PATHS}
          PATH_SUFFIXES lib
          NO_DEFAULT_PATH
          DOC "GSL library"
        )
        
        FIND_LIBRARY(GSL_GSLCBLAS_LIBRARY_MANUAL
          NAMES gslcblas libgslcblas cblas
          PATHS ${GSL_SEARCH_PATHS}
          PATH_SUFFIXES lib
          NO_DEFAULT_PATH
          DOC "GSL cblas library"
        )
        
        IF(GSL_GSL_LIBRARY_MANUAL AND GSL_GSLCBLAS_LIBRARY_MANUAL)
          SET(GSL_INCLUDE_DIR ${GSL_INCLUDE_DIR_MANUAL} CACHE STRING INTERNAL)
          SET(GSL_LIBRARIES ${GSL_GSL_LIBRARY_MANUAL} ${GSL_GSLCBLAS_LIBRARY_MANUAL})
          GET_FILENAME_COMPONENT(GSL_PREFIX ${GSL_INCLUDE_DIR_MANUAL} DIRECTORY)
          MESSAGE(STATUS "Using GSL from ${GSL_PREFIX} (found via CMAKE_PREFIX_PATH)")
          SET(GSL_FOUND 1)
          INCLUDE(FindPackageHandleStandardArgs)
          FIND_PACKAGE_HANDLE_STANDARD_ARGS(GSL DEFAULT_MSG GSL_INCLUDE_DIR GSL_GSL_LIBRARY_MANUAL GSL_GSLCBLAS_LIBRARY_MANUAL)
        ENDIF(GSL_GSL_LIBRARY_MANUAL AND GSL_GSLCBLAS_LIBRARY_MANUAL)
      ENDIF(GSL_INCLUDE_DIR_MANUAL)
    ENDIF(GSL_SEARCH_PATHS)
    
    # If not found manually, fall back to gsl-config
    IF(NOT GSL_FOUND)
      SET(GSL_CONFIG_PREFER_PATH 
        "$ENV{GSL_DIR}/bin"
        "$ENV{GSL_DIR}"
        "$ENV{GSL_HOME}/bin" 
        "$ENV{GSL_HOME}" 
        CACHE STRING "preferred path to GSL (gsl-config)")
      FIND_PROGRAM(GSL_CONFIG gsl-config
        ${GSL_CONFIG_PREFER_PATH}
        /usr/bin/
        )
      # MESSAGE("DBG GSL_CONFIG ${GSL_CONFIG}")
      
      IF (GSL_CONFIG) 
      # set CXXFLAGS to be fed into CXX_FLAGS by the user:
      EXEC_PROGRAM(${GSL_CONFIG}
	ARGS "--cflags"
	OUTPUT_VARIABLE GSL_CXX_FLAGS)
      
      # set INCLUDE_DIRS to prefix+include
      EXEC_PROGRAM(${GSL_CONFIG}
        ARGS "--prefix"
        OUTPUT_VARIABLE GSL_PREFIX)
      SET(GSL_INCLUDE_DIR ${GSL_PREFIX}/include CACHE STRING INTERNAL)

      # set link libraries and link flags
      EXEC_PROGRAM(${GSL_CONFIG}
	ARGS "--libs"
	OUTPUT_VARIABLE GSL_LIBRARIES)
      
      # extract link dirs for rpath  
      EXEC_PROGRAM(${GSL_CONFIG}
        ARGS "--libs"
        OUTPUT_VARIABLE GSL_CONFIG_LIBS )

      # split off the link dirs (for rpath)
      # use regular expression to match wildcard equivalent "-L*<endchar>"
      # with <endchar> is a space or a semicolon
      STRING(REGEX MATCHALL "[-][L]([^ ;])+" 
        GSL_LINK_DIRECTORIES_WITH_PREFIX 
        "${GSL_CONFIG_LIBS}" )
      #      MESSAGE("DBG  GSL_LINK_DIRECTORIES_WITH_PREFIX=${GSL_LINK_DIRECTORIES_WITH_PREFIX}")

      # remove prefix -L because we need the pure directory for LINK_DIRECTORIES
      
      IF (GSL_LINK_DIRECTORIES_WITH_PREFIX)
        STRING(REGEX REPLACE "[-][L]" "" GSL_LINK_DIRECTORIES ${GSL_LINK_DIRECTORIES_WITH_PREFIX} )
      ENDIF (GSL_LINK_DIRECTORIES_WITH_PREFIX)
      SET(GSL_EXE_LINKER_FLAGS "-Wl,-rpath,${GSL_LINK_DIRECTORIES}" CACHE STRING INTERNAL)
      #      MESSAGE("DBG  GSL_LINK_DIRECTORIES=${GSL_LINK_DIRECTORIES}")
      #      MESSAGE("DBG  GSL_EXE_LINKER_FLAGS=${GSL_EXE_LINKER_FLAGS}")

        #      ADD_DEFINITIONS("-DHAVE_GSL")
        #      SET(GSL_DEFINITIONS "-DHAVE_GSL")
        MARK_AS_ADVANCED(
          GSL_CXX_FLAGS
          GSL_INCLUDE_DIR
          GSL_LIBRARIES
          GSL_LINK_DIRECTORIES
          GSL_DEFINITIONS
        )
        MESSAGE(STATUS "Using GSL from ${GSL_PREFIX}")
        SET(GSL_FOUND 1)
        
      ELSE(GSL_CONFIG)
        MESSAGE("FindGSL.cmake: gsl-config not found. Please set it manually. GSL_CONFIG=${GSL_CONFIG}")
      ENDIF(GSL_CONFIG)
      
      IF(NOT GSL_FOUND)
        INCLUDE(FindPackageHandleStandardArgs)
        FIND_PACKAGE_HANDLE_STANDARD_ARGS(GSL DEFAULT_MSG GSL_CONFIG)
      ENDIF(NOT GSL_FOUND)
    ENDIF(NOT GSL_FOUND)

  ENDIF(UNIX)
ENDIF(WIN32)


IF(GSL_LIBRARIES)
  IF(GSL_INCLUDE_DIR OR GSL_CXX_FLAGS)
    SET(GSL_FOUND 1)
  ENDIF(GSL_INCLUDE_DIR OR GSL_CXX_FLAGS)
ENDIF(GSL_LIBRARIES)
