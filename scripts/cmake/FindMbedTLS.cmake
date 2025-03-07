set(MBEDTLS_ROOT_DIR
    "${MBEDTLS_ROOT_DIR}"
    CACHE PATH "Root to search for MBEDTLS")

include(FindPackageHandleStandardArgs)

if(MBEDTLS_USE_STATIC_LIBS)
  set(_MBEDTLS_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
  set(CMAKE_FIND_LIBRARY_SUFFIXES .a)

endif()

# Manually find
find_path(
  MbedTLS_INCLUDE_DIR
  NAMES mbedtls/ssl.h
  PATHS ${MBEDTLS_ROOT_DIR}
  PATH_SUFFIXES include
  NO_DEFAULT_PATH)

find_library(
  MbedTLS_TLS_LIBRARY
  NAMES mbedtls
  PATHS ${MBEDTLS_ROOT_DIR}
  PATH_SUFFIXES lib
  NO_DEFAULT_PATH)

find_library(
  MbedTLS_CRYPTO_LIBRARY
  NAMES mbedcrypto
  PATHS ${MBEDTLS_ROOT_DIR}
  PATH_SUFFIXES lib
  NO_DEFAULT_PATH)

find_library(
  MbedTLS_X509_LIBRARY
  NAMES mbedx509
  PATHS ${MBEDTLS_ROOT_DIR}
  PATH_SUFFIXES lib
  NO_DEFAULT_PATH)

find_package_handle_standard_args(
  MbedTLS REQUIRED_VARS MbedTLS_INCLUDE_DIR MbedTLS_TLS_LIBRARY
                        MbedTLS_CRYPTO_LIBRARY MbedTLS_X509_LIBRARY)

if(MbedTLS_FOUND)
  set(MbedTLS_INCLUDE_DIRS "${MbedTLS_INCLUDE_DIR}")
  set(MbedTLS_LIBRARIES "${MbedTLS_TLS_LIBRARY}" "${MbedTLS_CRYPTO_LIBRARY}"
                        "${MbedTLS_X509_LIBRARY}")

  if(NOT TARGET MbedTLS::libssl)
    add_library(MbedTLS::libssl UNKNOWN IMPORTED)
    set_target_properties(
      MbedTLS::libssl PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                                 "${MbedTLS_INCLUDE_DIR}")
    set_target_properties(
      MbedTLS::libssl PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C"
                                 IMPORTED_LOCATION "${MbedTLS_SSL_LIBRARY}")
  endif()

  if(NOT TARGET MbedTLS::libcrypto)
    add_library(MbedTLS::libcrypto UNKNOWN IMPORTED)
    set_target_properties(
      MbedTLS::libcrypto PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                                    "${MbedTLS_INCLUDE_DIR}")
    set_target_properties(
      MbedTLS::libcrypto
      PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C"
                 IMPORTED_LOCATION "${MbedTLS_CRYPTO_LIBRARY}")
  endif()

  if(NOT TARGET MbedTLS::libx509)
    add_library(MbedTLS::libx509 UNKNOWN IMPORTED)
    set_target_properties(
      MbedTLS::libx509 PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                                  "${MbedTLS_INCLUDE_DIR}")
    set_target_properties(
      MbedTLS::libx509 PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C"
                                  IMPORTED_LOCATION "${MbedTLS_X509_LIBRARY}")
  endif()

  mark_as_advanced(MbedTLS_INCLUDE_DIR MbedTLS_SSL_LIBRARY
                   MbedTLS_CRYPTO_LIBRARY MbedTLS_X509_LIBRARY)
endif()

mark_as_advanced(MBEDTLS_ROOT_DIR)

# Restore the original find library ordering
if(MBEDTLS_USE_STATIC_LIBS)
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${_MBEDTLS_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES})
endif()
