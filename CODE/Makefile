FC = gfortran
FFLAGS = -Wall -O2

all: p1.x

%.x: %.F90
	$(FC) $(FFLAGS) $< -o $@

clean:
	-rm -f *.x
	-rm -f *.o
	-rm -f *.mod
