set(JSONCPP_ROOT_DIR
    "${JSONCPP_ROOT_DIR}"
    CACHE PATH "Root to search for jsoncpp")

include(FindPackageHandleStandardArgs)

if(JSONCPP_USE_STATIC_LIBS)
  set(_JSONCPP_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
  set(CMAKE_FIND_LIBRARY_SUFFIXES .a)

endif()

# Manually find
find_path(
  JSONCPP_INCLUDE_DIR
  NAMES json/json.h
  PATHS ${JSONCPP_ROOT_DIR}
  PATH_SUFFIXES include
  NO_DEFAULT_PATH)

find_library(
  JSONCPP_LIBRARY
  NAMES jsoncpp
  PATHS ${JSONCPP_ROOT_DIR}
  PATH_SUFFIXES lib
  NO_DEFAULT_PATH)

find_package_handle_standard_args(JSONCPP REQUIRED_VARS JSONCPP_INCLUDE_DIR
                                                        JSONCPP_LIBRARY)

if(JSONCPP_FOUND)
  set(JSONCPP_INCLUDE_DIRS "${JSONCPP_INCLUDE_DIR}")
  set(JSONCPP_LIBRARIES "${JSONCPP_LIBRARY}")

  if(NOT TARGET JSONCPP::libjsoncpp)
    add_library(JSONCPP::libjsoncpp UNKNOWN IMPORTED)
    set_target_properties(
      JSONCPP::libjsoncpp PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                                     "${JSONCPP_INCLUDE_DIR}")
    set_target_properties(
      JSONCPP::libjsoncpp PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
                                     IMPORTED_LOCATION "${JSONCPP_SSL_LIBRARY}")
  endif()

  mark_as_advanced(JSONCPP_INCLUDE_DIR JSONCPP_LIBRARY)
endif()

mark_as_advanced(JSONCPP_ROOT_DIR)

# Restore the original find library ordering
if(JSONCPP_USE_STATIC_LIBS)
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${_JSONCPP_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES})
endif()
