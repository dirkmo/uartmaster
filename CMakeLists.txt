cmake_minimum_required(VERSION 3.8)

project(UartMasterSim)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

# Create a new executable target that will contain all your sources
add_executable(simulation sim/sim.cpp sim/uart.cpp)

# Add the Verilated circuit to the target
verilate(simulation COVERAGE TRACE
  INCLUDE_DIRS "sim/"
  VERILATOR_ARGS -O0 -x-assign 0 +librescan +libext+.v -y rtl/
  SOURCES rtl/UartMaster.v)
