# CMake GTest

CMake module to automatically add and configure GTest

## Installation:

add this repo as a submodule (don't forget to initialize subsubmodules) and include `GTest.cmake` in your top-level `CMakeLists.txt` file

## Usage:

### `create_test`

Use this function to create a test target. The target may include as many GTest suites as you like.

Options:
  - `NO_EXE`: do not create an executable for this test
  - `EXCLUDE_FROM_ALL`: exclude this target from target "all"
  
Arguments:
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
  - `FROM`: list of test targets that will make the test suite
  
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
