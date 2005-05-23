#  Tomasz Macura

INC = httpOMEIS.h httpOMEISaux.h
SRC = httpOMEIS.c httpOMEISaux.c
OBJ = httpOMEIS.o httpOMEISaux.o
LIB = libhttpOMEIS

targets: lib lib_mat
lib: compile $(INC) $(OBJ)
	ar rcs $(LIB).a $(OBJ)

compile: $(INC) $(SRC) 
	gcc -c -Wall -ansi $(SRC)

LIB_MAT = libhttpOMEIS_MAT

lib_mat: compile_mat $(INC) $(OBJ)
	ar rcs $(LIB_MAT).a $(OBJ)

compile_mat: $(INC) $(SRC)
	gcc -c -Wall -ansi $(SRC) -DMATLAB -I /Applications/MATLAB701/extern/include/
	
# Utilities for cleaning up your directory.  
# 'make clean' removes emacs backup files
# 'make cleaner' also removes all object files
# 'make cleanest' also removes the executable

clean:
	- rm -f *# *~ 
cleaner: clean
	- rm -f *.o
cleanest: cleaner
	- rm $(LIB).a