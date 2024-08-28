# Use in order to use the compress-optimized sbox. 
NSHARES?=2

# Directory created containing all the HDL files
DIR_HDL?=smaesh-hdl-d${NSHARES}

# path where the COMPRESS tool is located (root of the git)
DIR_COMPRESS_ROOT?=../sboxes-compress/compress

##################"
DIR_COMPRESS_GADGETS=$(DIR_COMPRESS_ROOT)/gadget_library
DIR_SBOX=sbox-d${NSHARES}
DIR_SBOX_COMPRESS=../sboxes-compress/work/circuits/canright_aes_sbox_dual_d${NSHARES}_l4

DIR_SMAESH_HDL=./aes_enc128_32bits_hpc

.PHONY: all

help:
	@echo "Generation of a single directory containing the synthetisable SMAesH HDL files."
	@echo "Variables:"
	@echo "    NSHARES: Amount of shares for optimal Sbox architecture."
	@echo "    DIR_HDL: Path to the generated directory"
	@echo "    DIR_COMPRESS_ROOT: Path to the COMPRESS repository."
	@echo "Targets:"
	@echo "    all: Generate the dir"

all: $(DIR_HDL) gather 

$(DIR_HDL):
	mkdir -p $(DIR_HDL)

gather:
	OUT_DIR=${DIR_HDL} ./gather_sources.sh $(DIR_SMAESH_HDL) $(DIR_SBOX) $(DIR_COMPRESS_GADGETS)/BIN $(DIR_COMPRESS_GADGETS)/MSK
	cp $(DIR_SBOX_COMPRESS)/canright_aes_sbox_dual.v $(DIR_HDL)
	cp $(DIR_SBOX_COMPRESS)/design.vh $(DIR_HDL)

clean:
	if [ -d $(DIR_HDL) ]; then rm -r $(DIR_HDL); fi
