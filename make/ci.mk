MK_COMMON ?= $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/common

include $(MK_COMMON)/*.mk

include $(wildcard $(3M_ROOT)/make/*.mk)

