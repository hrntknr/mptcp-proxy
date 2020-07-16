TARGET := mptcp_proxy

LLC ?= llc
CLANG ?= clang
CC ?= gcc

LIBBPF_DIR = ./libbpf/src/

PROXY_C = ${TARGET:=_kern.c}
PROXY_OBJ = ${PROXY_C:.c=.o}
OBJECT_LIBBPF = $(LIBBPF_DIR)/libbpf.a

CFLAGS ?= -I$(LIBBPF_DIR)
LDFLAGS ?= -L$(LIBBPF_DIR)

LIBS = -lbpf -lelf

all: llvm-check $(PROXY_OBJ)

.PHONY: clean $(CLANG) $(LLC)

clean:
	cd $(LIBBPF_DIR) && $(MAKE) clean;
	rm -f $(PROXY_OBJ)
	rm -f *.ll

llvm-check: $(CLANG) $(LLC)
	@for TOOL in $^ ; do \
		if [ ! $$(command -v $${TOOL} 2>/dev/null) ]; then \
			echo "*** ERROR: Cannot find tool $${TOOL}" ;\
			exit 1; \
		else true; fi; \
	done

$(OBJECT_LIBBPF):
	@if [ ! -d $(LIBBPF_DIR) ]; then \
		echo "Error: Need libbpf submodule"; \
		echo "May need to run git submodule update --init"; \
		exit 1; \
	else \
		cd $(LIBBPF_DIR) && $(MAKE) all; \
		mkdir -p root; DESTDIR=root $(MAKE) install_headers; \
	fi

$(PROXY_OBJ): %.o: %.c
	$(CLANG) -S \
	    -D __BPF_TRACING__ \
	    $(CFLAGS) \
	    -Wall \
	    -Wno-unused-value -Wno-pointer-sign \
	    -Wno-compare-distinct-pointer-types \
	    -O2 -emit-llvm -c -g $<
	$(LLC) -march=bpf -filetype=obj -o $@ ${@:.o=.ll}
