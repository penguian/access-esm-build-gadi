src/UM : src
	git clone accessdev.nci.org.au:/scratch/users/hxw599/submodels/UM $@

bin src :
	@mkdir -p $@


bin/um_hg3.exe: src/UM bin
	cd src/UM/compile; ./UM_exe_generator-ACCESS1.5

src/cice4.1: src
	git clone accessdev.nci.org.au:/scratch/users/hxw599/submodels/cice4.1 $@


