# this compiler flag is necessary as a fix for gtest because someone broke the
# build for windows+mingw

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR}/external/DownloadProject)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR}/external/cmake_utils)

include(DownloadProject)
include(CTest)
include(Utils)
enable_testing()

if(NOT gtest_already_downloaded)
    download_project(
            PROJ            gtest
            GIT_REPOSITORY  https://github.com/google/googletest.git
            GIT_TAG         a2b8a8e # I'd love to use a release but the last release doesn't work with MinGW
            TIMEOUT         10
    )

    set(gtest_already_downloaded TRUE CACHE STRING "" FORCE)
endif()

if(MINGW)
    # https://github.com/google/googletest/issues/920
    add_definitions("-D_EMULATE_GLIBC=0")
endif()

# Prevent GoogleTest from overriding our compiler/linker options
# when building with Visual Studio
if(MSVC)
    message(STATUS "MSVC detected, setting gtest_force_shared_crt")
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

    if(CMAKE_VERSION VERSION_GREATER 2.8.11)
        if(CMAKE_CXX_COMPILER_VERSION MATCHES 17.*)
            set(compiler_is_vs2012 TRUE)
        endif()
    else()
        include(CMakeDetermineVSServicePack)
        DetermineVSServicePack(vs_service_pack)

        if(vs_service_pack MATCHES "VC110*")
            set(compiler_is_vs2012 TRUE)
        endif()
    endif()

    # VS2012 doesn't support variadic templates, so we have to tell gtest not to use them
    if(compiler_is_vs2012)
        message(STATUS "VS2012 (toolset v110) detected. Disabling variadic templates in gtest")
        add_definitions("-DGTEST_HAS_TR1_TUPLE=0")
    endif()

endif()

# add gtest so we can use it's targets. EXCLUDE_FROM_ALL hides targets, except
# those that are dependencies of our own targets
add_subdirectory(${gtest_SOURCE_DIR} ${gtest_BINARY_DIR} EXCLUDE_FROM_ALL)


# in all CMake versions befor 2.8.11, header depencencies have to be added manually
if (CMAKE_VERSION VERSION_LESS 2.8.11)
    include_directories("${gtest_SOURCE_DIR}/include" "${gmock_SOURCE_DIR}/include")
endif()

function(create_test)
    cmake_parse_arguments(
            ARGS                                        # prefix of output variables
            "NO_EXE;EXCLUDE_FROM_ALL"  # list of names of the boolean arguments (only defined ones will be true)
            ""                                          # list of names of mono-valued arguments
            "SOURCES;DEPENDS"                           # list of names of multi-valued arguments (output variables are lists)
            ${ARGN}                                     # arguments of the function to parse, here we take the all original ones
    ) # remaining unparsed arguments can be found in ARGS_UNPARSED_ARGUMENTS

    set(dependencies ${ARGS_DEPENDS})

    list(LENGTH ARGS_UNPARSED_ARGUMENTS other_args_size)
    if(other_args_size EQUAL 1)
        set(name ${ARGS_UNPARSED_ARGUMENTS})
    else()
        message(FATAL_ERROR "too many or not enough unnamed arguments")
    endif()

    if(ARGS_SOURCES)
        set(sources ${ARGS_SOURCES})
    else()
        message(FATAL_ERROR "you must specify at least one source for the test")
    endif()

    if(ARGS_EXCLUDE_FROM_ALL)
        set(EXCLUDE_FROM_ALL "EXCLUDE_FROM_ALL")
    endif()

    add_library(${name} OBJECT ${sources} ${EXCLUDE_FROM_ALL})
    target_link_dependencies(${name} PUBLIC ${dependencies} gtest)

    set(${CMAKE_PROJECT_NAME}_all_tests "${${CMAKE_PROJECT_NAME}_all_tests};${name}" CACHE STRING "" FORCE)

    if(NOT ARGS_NO_EXE)
        add_executable(run_${name} "" ${EXCLUDE_FROM_ALL})
        target_link_dependencies(run_${name} ${name} gtest_main)
        add_test(NAME ${name} COMMAND run_${name})
    endif()
endfunction()

function(create_test_suite name)
    cmake_parse_arguments(
            ARGS                                        # prefix of output variables
            "EXCLUDE_FROM_ALL"  # list of names of the boolean arguments (only defined ones will be true)
            ""                                          # list of names of mono-valued arguments
            ""                           # list of names of multi-valued arguments (output variables are lists)
            ${ARGN}                                     # arguments of the function to parse, here we take the all original ones
    ) # remaining unparsed arguments can be found in ARGS_UNPARSED_ARGUMENTS

    if(ARGS_EXCLUDE_FROM_ALL)
        set(EXCLUDE_FROM_ALL "EXCLUDE_FROM_ALL")
    endif()

    set(tests_in_suite ${ARGS_UNPARSED_ARGUMENTS} CACHE STRING "" FORCE)

    add_executable(${name} "" ${EXCLUDE_FROM_ALL})
    target_link_dependencies(${name} PUBLIC ${tests_in_suite} PRIVATE gtest_main)
    add_test(NAME ${name} COMMAND ${name})
endfunction()
