SIM_DIR 	= $(shell pwd)
PLOT_DIR 	= $(SIM_DIR)/plots
DATA_DIR 	= $(SIM_DIR)/data
INFR_DIR 	= $(DATA_DIR)/infrastructures
RES_DIR 	= $(SIM_DIR)/results
GML_DIR 	= $(DATA_DIR)/gml
FLOW_DIR 	= $(DATA_DIR)/flows


PYTHON		= $(shell which python3)

GML_FLAG	= $(shell ls $(GML_DIR) | xargs -n1 basename -s .gml | xargs -n1 echo -g )
N_FLOWS     = 1 2 5 10 15 20 25
# create flows flags similary to infrs_flag but starting from N_FLOWS, using makefile syntax
FLOWS_FLAG	= $(shell for i in $(N_FLOWS); do echo -n "-f $$i "; done)
TARGETS 	= clean run plot

.ONESHELL:
.PHONY: all clean

all: $(TARGETS)

clean-infr:
	rm -rf $(INFR_DIR)/*

clean-flow:
	rm -rf $(FLOW_DIR)/*

clean-res:
	rm -rf $(RES_DIR)/*

clean-plot:
	rm -rf $(PLOT_DIR)/*

clean: clean-infr clean-flow clean-res clean-plot

plot:
	$(PYTHON) $(SIM_DIR)/plot.py

run:
	$(PYTHON) $(SIM_DIR)/main.py -s 391997 $(GML_FLAG) $(FLOWS_FLAG)