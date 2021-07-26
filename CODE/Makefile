FC = gfortran
FFLAGS = -Wall -O2 -fopenmp -fcoarray=single

all: sequential.x coarray.x do-concurrent.x openmp.x

numerot.o: numerot.F90
	$(FC) $(FFLAGS) -c $< -o $@

%.x: %.F90 numerot.o
	$(FC) $(FFLAGS) numerot.o $< -o $@

clean:
	-rm -f *.x
	-rm -f *.o
	-rm -f *.mod
