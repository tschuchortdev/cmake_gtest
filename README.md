# CMake GTest

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/tschuchortdev/cmake_gtest/issues)

CMake module to automatically add and configure GTest

## Installation:

1. add this repo as a submodule (you must already be in a git repository to do this) and don't forget to initialize the submodules recursively:

    `git submodule add https://github.com/tschuchortdev/cmake_gtest external/gtest`
    
    `git submodule update --init --recursive`

2. include `GTest.cmake` in your top-level `CMakeLists.txt` file:

    `include(external/gtest/GTest.cmake)`

## Usage:

### `create_test`

Use this function to create a test target. The target may include as many GTest suites as you like.

Options:
  - `NO_EXE`: do not create an executable for this test
  - `NO_MAIN`: do not link gtest_main. Use this option if you want to use your own main function to run the tests (Although this should never be necessary. Use test fixtures instead!)
  - `EXCLUDE_FROM_ALL`: exclude this target from target "all"
  
Arguments:
  - target name
  - `SOURCES`: list of the tests source files. You should use absolute paths here
  - `DEPENDS`: list of targets (libraries) that this target depends on
  
Example: 

    create_test(
            my_test_target
            NO_EXE
            SOURCES "~/myproject/test1.c" "~/myproject/test2.c"
            DEPENDS libtarget1 libtarget2)
            

### `create_test_suite`

Use this function to create a test suite target from several test targets. It is even possible to combine other test suite targets into a new test suite, much like you can combine regular library targets in CMake.

Options:
  - `EXCLUDE_FROM_ALL`: exclude this target from target "all"

Arguments:
  - target name
  - list of test targets that will make the test suite
  
Example:

    create_test_suite(
            my_test_suite_target
            my_test_target1 my_test_target2)
            
You can find a list of all test targets that you have created in `${CMAKE_PROJECT_NAME}_all_tests`:

    create_test_suite(
            all_tests
            "${${CMAKE_PROJECT_NAME}_all_tests}")
            
       
# WARNING:

If you instruct ctest to run all targets, some tests may be run multiple times. For example if you have tests targets that are included in more than one test suite, or you create executables for test targets that are in a test suite by not specifying `NO_EXE`. It is therefore recommended to create a test suite all_tests and run that instead.
