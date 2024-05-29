# Compiler settings - Can be customized.
CC = nvcc
CXXFLAGS = -std=c++11 -arch=compute_70 -I/usr/local/cuda-10.2/include
LDFLAGS = -L/usr/local/cuda-10.2/lib64 -lcudart

# Makefile settings - Can be customized.
APPNAME = vecAdd
EXT = .cu
SRCDIR = /home/marc/Escritorio/BSC_Training_Intro_to_CUDA/cuda_2024/benchmarks/vecAdd/src/cuda/local
OBJDIR = obj

############## Do not change anything from here downwards! #############
SRC = $(wildcard $(SRCDIR)/*$(EXT))
OBJ = $(SRC:$(SRCDIR)/%$(EXT)=$(OBJDIR)/%.o)
DEP = $(OBJ:$(OBJDIR)/%.o=%.d)
# UNIX-based OS variables & settings
RM = rm -f
DELOBJ = $(OBJ)

########################################################################
####################### Targets beginning here #########################
########################################################################

all: $(APPNAME)

# Builds the app
$(APPNAME): $(OBJ)
	$(CC) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

# No dependency rules for CUDA in this simple template, they can be added if necessary.
# Dependency generation in CUDA projects can be more complex and is often omitted in simple projects.

# Includes all .h files and CUDA generated dependency files if any.
-include $(DEP)

# Building rule for .o files and its .cu in combination with all .h
$(OBJDIR)/%.o: $(SRCDIR)/%$(EXT)
	mkdir -p $(OBJDIR)
	$(CC) $(CXXFLAGS) -o $@ -c $<

################### Cleaning rules for Unix-based OS ###################
# Cleans complete project
.PHONY: clean
clean:
	$(RM) $(DELOBJ) $(APPNAME)

# Note: Dependency files (.d) are not used in this modified Makefile, so the cleandep target is omitted.
