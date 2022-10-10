FC = gfortran
FCFLAGS = -g -std=f2008 -fall-intrinsics -Wall -Wextra -Werror

CC = gcc
CFLAGS = -g -std=c11 -Wall -Wextra -Werror

all: handle_f.x handle_c.x

handle_f.x: handle.F90
	$(FC) $(FCFLAGS) $< -o $@

handle_c.x: handle.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	-rm -f *.x *.o *.mod
	-rm -fr *.dSYM
