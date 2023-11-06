cmake_minimum_required(VERSION 3.10)
project(mirteam)

#set(CMAKE_CXX_STANDARD 11)
#set(CMAKE_CXX_STANDARD_REQUIRED ON)
#set(CMAKE_CXX_EXTENSIONS OFF)

# Notify CMake that we have module files to find packages/libs.
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/modules/")

find_package(PAM REQUIRED)

# Check if we found PAM.
if (NOT PAM_FOUND)
    message(FATAL_ERROR "PAM library was not found.")
endif ()

# Source configuration.
include_directories(
   ${PAM_INCLUDE_DIR}
   ${CMAKE_BINARY_DIR}
   ${CMAKE_CURRENT_BINARY_DIR}
)

set(EXECUTABLE_NAME "pamdule")

# Add sources to this project's executable.
# add_executable(${EXECUTABLE_NAME}
    
#     "storepassword.c"
# )
# add_library(${PROJECT_NAME} SHARED ${SOURCES} ${PAM_LIBRARIES})

# # Install library
# install(TARGETS ${PROJECT_NAME} DESTINATION lib/${PROJECT_NAME})

# add_library(${EXECUTABLE_NAME}, "storepassword.c")
# target_link_libraries(${EXECUTABLE_NAME}
    
# )
set(modules warn storepassword)

foreach(module ${modules})

    set(WARN_FILE ${module}.so)
    # gcc -fPIC -fno-stack-protector -c warn.c && ld -x --shared -o /lib/security/warn.so warn.o  
    set(WARN_CMD "gcc" "-fPIC" "-fno-stack-protector" "-c" ../${module}.c)
    set(WARN_LD_CMD "ld" "-x" "--shared" "-o" ${module}.so ${module}.o)
    # set(KBUILD_CMD $(MAKE) -C ${PAM_INCLUDE_DIR} modules M=${CMAKE_CURRENT_BINARY_DIR} src=${CMAKE_CURRENT_SOURCE_DIR})

    # Generate the Kbuild file through cmake.
    # FILE(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/Kbuild "obj-m := warn.so")

    add_custom_command(OUTPUT ${WARN_FILE}
            COMMAND ${WARN_CMD}
            COMMAND ${WARN_LD_CMD}
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            DEPENDS ${module}.c VERBATIM)
            install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${module}.so
            DESTINATION /lib/security/)
    
    add_custom_target(mirteam_${module} ALL DEPENDS ${WARN_FILE})
endforeach(module ${modules})

# set(WARN_FILE warn.so)
# # gcc -fPIC -fno-stack-protector -c warn.c && ld -x --shared -o /lib/security/warn.so warn.o  
# set(WARN_CMD "gcc" "-fPIC" "-fno-stack-protector" "-c" "../warn.c")
# set(WARN_LD_CMD "ld" "-x" "--shared" "-o" "/lib/security/warn.so" "warn.o")
# # set(KBUILD_CMD $(MAKE) -C ${PAM_INCLUDE_DIR} modules M=${CMAKE_CURRENT_BINARY_DIR} src=${CMAKE_CURRENT_SOURCE_DIR})

# # Generate the Kbuild file through cmake.
# # FILE(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/Kbuild "obj-m := warn.so")

# add_custom_command(OUTPUT ${WARN_FILE}
#         COMMAND ${WARN_CMD}
#         COMMAND ${WARN_LD_CMD}
#         WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
#         DEPENDS warn.c VERBATIM)

# add_custom_target(mirteam ALL DEPENDS ${WARN_FILE})
# Parse c files
add_library(dummy_target warn.c)
