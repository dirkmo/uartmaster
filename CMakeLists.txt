cmake_minimum_required(VERSION 3.8)

project(UartMasterSim)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()


set(CMAKE_BUILD_TYPE DEBUG)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}-O0 -g")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0 -g")


# Create a new executable target that will contain all your sources
add_executable(simulation sim/sim.cpp sim/uart.cpp)

# Add the Verilated circuit to the target
verilate(simulation TRACE
  INCLUDE_DIRS "sim/"
  VERILATOR_ARGS -CFLAGS "-g" -O0 -x-assign 0 +librescan +libext+.v -y rtl/
  SOURCES rtl/UartMasterSlave.v)
