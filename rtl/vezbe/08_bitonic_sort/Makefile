ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# Global parameters
DATA_WIDTH   ?= 8
NUM_ELEMENTS ?= 8

PATTERN       = bitonic_sort
IVERILOG_FLAGS = -DDATA_WIDTH=$(DATA_WIDTH) -DNUM_ELEMENTS=$(NUM_ELEMENTS)

include ../common.mk