set(CURL_ROOT_DIR
    "${CURL_ROOT_DIR}"
    CACHE PATH "Root to search for CURL")

include(FindPackageHandleStandardArgs)

if(CURL_USE_STATIC_LIBS)
  set(_CURL_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
  set(CMAKE_FIND_LIBRARY_SUFFIXES .a)

endif()

find_library(
  CURL_LIBRARY
  NAMES curl
  PATHS ${CURL_ROOT_DIR}
  PATH_SUFFIXES lib
  NO_DEFAULT_PATH)

# Manually find
find_path(
  CURL_INCLUDE_DIR
  NAMES curl/curl.h
  PATHS ${CURL_ROOT_DIR}
  PATH_SUFFIXES include
  NO_DEFAULT_PATH)

find_package_handle_standard_args(CURL REQUIRED_VARS CURL_INCLUDE_DIR
                                                     CURL_LIBRARY)

if(CURL_FOUND)
  set(CURL_INCLUDE_DIRS "${CURL_INCLUDE_DIR}")
  set(CURL_LIBRARIES "${CURL_LIBRARY}")

  if(NOT TARGET CURL::libcurl)
    add_library(CURL::libcurl UNKNOWN IMPORTED)
    set_target_properties(CURL::libcurl PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                                                   "${CURL_INCLUDE_DIR}")
    set_target_properties(
      CURL::libcurl PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C"
                               IMPORTED_LOCATION "${CURL_LIBRARY}")

  endif()

  mark_as_advanced(CURL_INCLUDE_DIR CURL_LIBRARY)
endif()

mark_as_advanced(CURL_ROOT_DIR)

# Restore the original find library ordering
if(CURL_USE_STATIC_LIBS)
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${_CURL_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES})
endif()
