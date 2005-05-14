#  Tomasz Macura

INC = httpOMEIS.h httpOMEISaux.h
SRC = httpOMEIS.c httpOMEISaux.c
OBJ = httpOMEIS.o httpOMEISaux.o
LIB = libhttpOMEIS

lib: compile $(INC) $(OBJ)
	ar rcs $(LIB).a $(OBJ)

compile: $(INC) $(SRC) 
	gcc -c -Wall -ansi $(SRC)
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