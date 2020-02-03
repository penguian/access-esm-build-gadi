src/UM : src
	#git clone accessdev.nci.org.au:/scratch/users/hxw599/submodels/UM $@
	#RN=$$RANDOM ;\
	#ssh accessdev.nci.org.au "source ~/.bash_profile ; mkdir -p /scratch/users/$$USER/tmp/$$RN/ ; cd /scratch/users/$$USER/tmp/$$RN ; svn co https://access-svn.nci.org.au/svn/cmip5/trunk_ESM1.5/submodels/UM ; rm /scratch/users/$$USER/tmp/$$RN/UM/ummodel_hg3/bin/fcm_env.ksh " ; \
	#scp -r accessdev.nci.org.au:/scratch/users/$$USER/tmp/$$RN/UM $@
	scp -r accessdev.nci.org.au:/scratch/users/hxw599/access-esm/sources/UM $@
	cp scripts/UM_exe_generator-ACCESS1.5 $@/compile/

bin src :
	@mkdir -p $@

bin/um_hg3.exe: src/UM bin
	cd src/UM/compile; ./compile_ACCESS1.5

src/cice4.1: src
	git clone accessdev.nci.org.au:/scratch/users/hxw599/submodels/cice4.1 $@

bin/cice-12p: src/cice4.1
	cd $</compile; ./comp_access-cm_cice.RJ.nP-mct 12

