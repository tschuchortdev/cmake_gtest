# this compiler flag is necessary as a fix for gtest because someone broke the
# build for windows+mingw

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR}/external/DownloadProject)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR}/external/ucm/cmake)

include(DownloadProject)
include(Ucm)
include(CTest)
enable_testing()

ucm_add_flags("-D_EMULATE_GLIBC=0")

if(gtest_already_downloaded)
    message(WARNING "gtest included more than once")
endif()

download_project(
        PROJ            gtest
        GIT_REPOSITORY  https://github.com/google/googletest.git
        GIT_TAG         a2b8a8e # I'd love to use a release but the last release doesn't work with MinGW
        TIMEOUT         10
)

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
        ucm_add_flags("-DGTEST_HAS_TR1_TUPLE=0")
    endif()

endif()

# add gtest so we can use it's targets. EXCLUDE_FROM_ALL hides targets, except
# those that are dependencies of our own targets
add_subdirectory(${gtest_SOURCE_DIR} ${gtest_BINARY_DIR} EXCLUDE_FROM_ALL)


# in all CMake versions befor 2.8.11, header depencencies have to be added manually
if (CMAKE_VERSION VERSION_LESS 2.8.11)
    include_directories("${gtest_SOURCE_DIR}/include" "${gmock_SOURCE_DIR}/include")
endif()

set(gtest_already_downloaded TRUE CACHE STRING "" FORCE)

function(create_test)
    cmake_parse_arguments(
            ARGS                                        # prefix of output variables
            "NO_EXE"  # list of names of the boolean arguments (only defined ones will be true)
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

    add_library(${name} OBJECT EXCLUDE_FROM_ALL ${sources})
    set(${CMAKE_PROJECT_NAME}_all_tests "${${CMAKE_PROJECT_NAME}_all_tests};${name}" CACHE STRING "" FORCE)

    #set(dependencies "${dependencies};gtest")
    list(APPEND dependencies gtest)

    foreach(dependency ${dependencies})
        target_include_directories(${name} PRIVATE $<TARGET_PROPERTY:${dependency},INTERFACE_INCLUDE_DIRECTORIES>)
        target_compile_definitions(${name} PRIVATE $<TARGET_PROPERTY:${dependency},INTERFACE_COMPILE_DEFINITIONS>)
        target_compile_options(${name} PRIVATE $<TARGET_PROPERTY:${dependency},INTERFACE_COMPILE_OPTIONS>)
    endforeach()

    set_target_properties(${name} PROPERTIES DEPENDENCIES "${dependencies}")

    if(NOT ARGS_NO_EXE)
        add_executable(run_${name} EXCLUDE_FROM_ALL $<TARGET_OBJECTS:${name}>)
        target_link_libraries(run_${name} PRIVATE ${dependencies} gtest_main)
        add_test(NAME ${name} COMMAND run_${name})
    endif()
endfunction()

function(create_test_suite)
    cmake_parse_arguments(
            ARGS                                        # prefix of output variables
            ""  # list of names of the boolean arguments (only defined ones will be true)
            ""                                          # list of names of mono-valued arguments
            "FROM"                           # list of names of multi-valued arguments (output variables are lists)
            ${ARGN}                                     # arguments of the function to parse, here we take the all original ones
    ) # remaining unparsed arguments can be found in ARGS_UNPARSED_ARGUMENTS

    list(LENGTH ARGS_UNPARSED_ARGUMENTS other_args_size)
    if(other_args_size EQUAL 1)
        set(name ${ARGS_UNPARSED_ARGUMENTS})
    else()
        message(FATAL_ERROR "too many or not enough unnamed arguments")
    endif()

    if(ARGS_FROM)
        set(tests ${ARGS_FROM})
    else()
        message(FATAL_ERROR "you have to pass at least one test target to create_test_suite()")
    endif()

    add_executable(${name} EXCLUDE_FROM_ALL "")

    foreach(test ${tests})
        target_sources(${name} PRIVATE $<TARGET_OBJECTS:${test}>)
        target_link_libraries(${name} PRIVATE $<TARGET_PROPERTY:${test},DEPENDENCIES>)
    endforeach()

    target_link_libraries(${name} PRIVATE gtest_main)
    add_test(NAME ${name} COMMAND ${name})
endfunction()
