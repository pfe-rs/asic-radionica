ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# Global parameters
DATA_WIDTH ?= 8
ADDRESS_WIDTH ?= 6

PATTERN = fifo
IVERILOG_FLAGS = -DDSIZE=$(DATA_WIDTH) -DASIZE=$(ADDRESS_WIDTH)

include ../common.mk
