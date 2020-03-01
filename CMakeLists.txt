cmake_minimum_required(VERSION 3.2)

project(hpvm_julia)

find_package(LLVM REQUIRED)

include_directories(${LLVM_INCLUDE_DIRS})

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall")

add_library(
    llvm_support SHARED
    llvm_support.cxx
)

# Link against LLVM libraries
target_link_libraries(llvm_support)
