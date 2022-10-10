FC = gfortran
FCFLAGS = -g -std=f2008 -fall-intrinsics -Wall -Wextra -Werror

CC = gcc
CFLAGS = -g -std=c11 -Wall -Wextra -Werror

all: handle_f.x handle_c.x check_f.x check_c.x

%_f.x: %.F90
	$(FC) $(FCFLAGS) $< -o $@

%_c.x: %.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	-rm -f *.x *.o *.mod
	-rm -fr *.dSYM
