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

    set(WARN_FILE ${module}.so)
    # gcc -fPIC -fno-stack-protector -c warn.c && ld -x --shared -o /lib/security/warn.so warn.o  
    set(WARN_CMD "gcc" "-fPIC" "-fno-stack-protector" "-c" ../${module}.c)
    set(WARN_LD_CMD "ld" "-x" "--shared" "-o" ${module}.so ${module}.o)

    add_custom_command(OUTPUT ${WARN_FILE}
            COMMAND ${WARN_CMD}
            COMMAND ${WARN_LD_CMD}
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            DEPENDS ${module}.c VERBATIM)
            install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${module}.so
            DESTINATION /lib/security/)
    
    add_custom_target(mirte_pam_${module} ALL DEPENDS ${WARN_FILE})
endforeach(module ${modules})
