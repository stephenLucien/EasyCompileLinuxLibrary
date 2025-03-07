set(MOSQUITTO_ROOT_DIR
    "${MOSQUITTO_ROOT_DIR}"
    CACHE PATH "Root to search for mosquitto")

include(FindPackageHandleStandardArgs)

if(MOSQUITTO_USE_STATIC_LIBS)
  set(_mosquitto_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES
      ${CMAKE_FIND_LIBRARY_SUFFIXES})
  set(CMAKE_FIND_LIBRARY_SUFFIXES .a)

  find_library(
    mosquitto_LIBRARY
    NAMES mosquitto_static
    PATHS ${MOSQUITTO_ROOT_DIR}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH)

  find_library(
    mosquittopp_LIBRARY
    NAMES mosquittopp_static
    PATHS ${MOSQUITTO_ROOT_DIR}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH)

else()
  find_library(
    mosquitto_LIBRARY
    NAMES mosquitto
    PATHS ${MOSQUITTO_ROOT_DIR}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH)

  find_library(
    mosquittopp_LIBRARY
    NAMES mosquittopp
    PATHS ${MOSQUITTO_ROOT_DIR}
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH)
endif()

# Manually find
find_path(
  mosquitto_INCLUDE_DIR
  NAMES mosquitto.h
  PATHS ${MOSQUITTO_ROOT_DIR}
  PATH_SUFFIXES include
  NO_DEFAULT_PATH)

find_package_handle_standard_args(mosquitto REQUIRED_VARS mosquitto_INCLUDE_DIR
                                                          mosquitto_LIBRARY)

if(mosquitto_FOUND)
  set(mosquitto_INCLUDE_DIRS "${mosquitto_INCLUDE_DIR}")
  set(mosquitto_LIBRARIES "${mosquitto_LIBRARY}" "${mosquittopp_LIBRARY}")
  if(NOT TARGET mosquitto::mosquitto)
    add_library(mosquitto::mosquitto UNKNOWN IMPORTED)
    set_target_properties(
      mosquitto::mosquitto PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                                      "${mosquitto_INCLUDE_DIR}")
    set_target_properties(
      mosquitto::mosquitto PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C"
                                      IMPORTED_LOCATION "${mosquitto_LIBRARY}")

  endif()
  if(NOT TARGET mosquitto::mosquittopp)
    add_library(mosquitto::mosquittopp UNKNOWN IMPORTED)
    set_target_properties(
      mosquitto::mosquittopp PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                                        "${mosquitto_INCLUDE_DIR}")
    set_target_properties(
      mosquitto::mosquittopp
      PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C" IMPORTED_LOCATION
                                                       "${mosquittopp_LIBRARY}")

  endif()
  mark_as_advanced(mosquitto_INCLUDE_DIR mosquitto_LIBRARY mosquittopp_LIBRARY)
endif()

mark_as_advanced(MOSQUITTO_ROOT_DIR)

# Restore the original find library ordering
if(MOSQUITTO_USE_STATIC_LIBS)
  set(CMAKE_FIND_LIBRARY_SUFFIXES
      ${_mosquitto_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES})
endif()
