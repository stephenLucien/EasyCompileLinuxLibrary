set(JSON_ROOT_DIR
    "${JSON_ROOT_DIR}"
    CACHE PATH "Root to search for json")

include(FindPackageHandleStandardArgs)

# Manually find
find_path(
  json_INCLUDE_DIR
  NAMES nlohmann/json.hpp
  PATHS ${JSON_ROOT_DIR}
  PATH_SUFFIXES include
  NO_DEFAULT_PATH)

find_package_handle_standard_args(json REQUIRED_VARS json_INCLUDE_DIR)

if(json_FOUND)
  set(json_INCLUDE_DIRS "${json_INCLUDE_DIR}")
  mark_as_advanced(json_INCLUDE_DIR)
endif()

mark_as_advanced(JSON_ROOT_DIR)
