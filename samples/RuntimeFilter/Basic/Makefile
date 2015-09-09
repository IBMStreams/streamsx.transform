.PHONY: all clean 

SPLC_FLAGS = -a -t ../../../com.ibm.streamsx.transform
SPLC = $(STREAMS_INSTALL)/bin/sc

SPL_CMD_ARGS ?= 
SPL_MAIN_COMPOSITE = Main

all: standalone

standalone:
	$(SPLC) $(SPLC_FLAGS) -T -M $(SPL_MAIN_COMPOSITE) $(SPL_CMD_ARGS)


clean: 
	$(SPLC) $(SPLC_FLAGS) -C -M $(SPL_MAIN_COMPOSITE)

