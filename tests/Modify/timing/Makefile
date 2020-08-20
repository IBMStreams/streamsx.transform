# Copyright (C)2015, International Business Machines Corporation
# and others.  All rights reserved.

.PHONY: all clean 

SPLC_FLAGS = -a -t ../../com.ibm.streamsx.transform
SPLC = $(STREAMS_INSTALL)/bin/sc

SPL_CMD_ARGS ?= 


standalone:
	$(SPLC) $(SPLC_FLAGS) -T -M TestModify $(SPL_CMD_ARGS) --output-dir=output/modify
	$(SPLC) $(SPLC_FLAGS) -T -M TestFunctor $(SPL_CMD_ARGS) --output-dir=output/functor


clean: 
	$(SPLC) $(SPLC_FLAGS) -C -M $(SPL_MAIN_COMPOSITE)

