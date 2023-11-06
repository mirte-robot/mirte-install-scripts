cmake_minimum_required(VERSION 3.10)
project(mirte_pam)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/modules/")

find_package(PAM REQUIRED)

# Check if we found PAM.
if (NOT PAM_FOUND)
    message(FATAL_ERROR "PAM library was not found. Install: sudo apt-get install libpam0g-dev")
endif ()

include_directories(
   ${PAM_INCLUDE_DIR}
   ${CMAKE_BINARY_DIR}
   ${CMAKE_CURRENT_BINARY_DIR}
)

set(modules warn storepassword)

foreach(module ${modules})
    add_library(mirte_pam_${module} SHARED ${module}.c)
    
    find_package(json-c CONFIG)
    target_link_libraries(mirte_pam_${module} PRIVATE json-c::json-c)

    install(TARGETS mirte_pam_${module} DESTINATION /lib/security/)

endforeach(module ${modules})

add_executable(myprogram test.c storepassword.c)
target_link_libraries(myprogram PRIVATE json-c::json-c)

# cmake_minimum_required(VERSION 2.4.0)

# project(mycustomlib)

# # Find source files
# file(GLOB SOURCES warn.c)


# # Create shared library
# add_library(${PROJECT_NAME} SHARED ${SOURCES})

# Install library
