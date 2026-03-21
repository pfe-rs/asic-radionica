ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# Global parameters
DATA_WIDTH ?= 8

PATTERN = mux
IVERILOG_FLAGS = "-DN=$(DATA_WIDTH)"

include ../common.mk
