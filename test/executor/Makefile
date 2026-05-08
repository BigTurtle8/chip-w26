SIM ?= icarus
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../../src

VERILOG_SOURCES += $(SRC_DIR)/executor.v
VERILOG_SOURCES += $(PWD)/tb_executor.v

TOPLEVEL = tb
COCOTB_TEST_MODULES = test

include $(shell cocotb-config --makefiles)/Makefile.sim