#################################################################
#  CMake configure file for Monte Carlo eXtreme (MCX)
#  Qianqian Fang <q.fang at neu.edu>
#  2018/08/26
#################################################################

cmake_minimum_required(VERSION 3.10)


# Add link directories
link_directories(zmat)
add_subdirectory(zmat)
project(MCX CXX C)
set(CMAKE_C_FLAGS "-g -Wall -fopenmp -fPIC")
set(CMAKE_C_COMPILER hipcc)
include_directories(cjson ubj zmat zmat/easylzma)

option(STATIC_LIB "Build static library" ON)

list(APPEND CMAKE_PREFIX_PATH /opt/rocm/hip /opt/rocm /usr/bin)
find_package(hip)
set(CMAKE_CXX_COMPILER hipcc)


# Find all files
file(GLOB MCX_FILES "*.h" "*.cpp" "cjson/*.c" "cjson/*.h")
add_executable(mcx_exe ${MCX_FILES})
add_definitions(-DSAVE_DETECTORS)

# Create executable
# Link with HIP
target_link_libraries(mcx_exe hip::device)
