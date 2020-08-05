TARGET := mptcp_proxy

LLC ?= llc
CLANG ?= clang
CC ?= gcc

LIBBPF_DIR = ../libbpf/src/

KERN_C = ${TARGET:=_kern.c}
KERN_OBJ = ${KERN_C:.c=.o}

USER_C = ${TARGET:=_user.c}
USER_OBJ = ${USER_C:.c=.o}

OBJECT_LIBBPF = $(LIBBPF_DIR)/libbpf.a

CFLAGS ?= -I$(LIBBPF_DIR)
CFLAGS += -I./headers/
LDFLAGS ?= -L$(LIBBPF_DIR)

USER_CFLAGS ?= $(CFLAGS)
KERN_CFLAGS ?= $(CFLAGS)

LIBS = -lbpf -lelf

all: llvm-check $(KERN_OBJ) $()

.PHONY: clean $(CLANG) $(LLC)
clean:
	cd $(LIBBPF_DIR) && $(MAKE) clean;
	rm -f $(KERN_OBJ)
	rm -f *.ll

.PHONY: llvm-check $(CLANG) $(LLC)
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
		cd $(LIBBPF_DIR) && $(MAKE) all OBJDIR=.; \
		mkdir -p build; $(MAKE) install_headers DESTDIR=build OBJDIR=.; \
	fi

$(KERN_OBJ): %.o: %.c Makefile
	$(CLANG) -S \
			-D __BPF_TRACING__ \
			$(KERN_CFLAGS) \
			-Wall \
			-Wno-unused-value -Wno-pointer-sign \
			-Wno-compare-distinct-pointer-types \
			-O2 -emit-llvm -c -g $<
	$(LLC) -march=bpf -filetype=obj -o $@ ${@:.o=.ll}


$(USER_OBJ): %.o: %.c $(OBJECT_LIBBPF) Makefile
	$(CC) -Wall $(USER_CFLAGS) $(LDFLAGS) -o $@ $< $(LIBS)
