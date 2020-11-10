.PHONY: all clean 

SPLC_FLAGS = -a -t ../../../com.ibm.streamsx.transform
ifdef STREAMS_BUILDSERVICE
    SPLC_FLAGS = -a -t ../toolkits:$(STREAMS_INSTALL)/toolkits
endif
SPLC = $(STREAMS_INSTALL)/bin/sc

SPL_CMD_ARGS ?= 
SPL_MAIN_COMPOSITE = Main

all: distributed

distributed:
	$(SPLC) $(SPLC_FLAGS) -M $(SPL_MAIN_COMPOSITE) $(SPL_CMD_ARGS)

clean: 
	$(SPLC) $(SPLC_FLAGS) -C -M $(SPL_MAIN_COMPOSITE)

