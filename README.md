# CMake GTest

CMake module to automatically add and configure GTest

## Installation:

add this repo as a submodule (don't forget to initialize subsubmodules) and include `GTest.cmake` in your top-level `CMakeLists.txt` file

## Usage:

### `create_test`

Use this function to create a test target. The target may include as many GTest suites as you like.

Options:
  - `NO_EXE`: do not create an executable for this test
  
Arguments:
  - `SOURCES`: list of the tests source files. You should use absolute paths here
  - `DEPENDS`: list of targets (libraries) that this target depends on
  
Example: 

    create_test(
            my_test_target
            NO_EXE
            SOURCES "~/myproject/test1.c" "~/myproject/test2.c"
            DEPENDS libtarget1 libtarget2)
            
