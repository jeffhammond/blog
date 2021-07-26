FC = gfortran
FFLAGS = -Wall -O2

all: sequential.x

numerot.o: numerot.F90
	$(FC) $(FFLAGS) -c $< -o $@

%.x: %.F90 numerot.o
	$(FC) $(FFLAGS) numerot.o $< -o $@

clean:
	-rm -f *.x
	-rm -f *.o
	-rm -f *.mod
