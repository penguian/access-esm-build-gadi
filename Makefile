
# This section contains some scripts and script-snippets for the build process
######################################

# the environment.sh script
#-----------------------------
define ENVIRONMENT
module purge
#from AMIP umui
module use ~access/modules
module load intel-compiler/2019.3.199
module load intel-mkl/2019.3.199
module load netcdf/4.7.1
module load openmpi/4.0.2
module load fcm/2019.09.0
module load um 
module load dummygrib 

# OASIS BEGIN
module load oasis3-mct-local/ompi.4.0.2
# OASIS END

# GCOM BEGIN
module load gcom/7.0_ompi.4.0.2
# GCOM END

#NETCDF in addition to module load, adding explicit paths to netcdf.inc
export C_INCLUDE_PATH=/apps/netcdf/4.7.1/include/Intel:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=/apps/netcdf/4.7.1/include/Intel:$CPLUS_INCLUDE_PATH
export CPATH=/apps/netcdf/4.7.1/include/Intel:$CPATH
export FPATH=/apps/netcdf/4.7.1/include/Intel:$FPATH

##DUMMYGRIB
export RPATH=/g/data/p66/pbd562/projects/access/apps/dummygrib/lib:$RPATH
export LD_RUN_PATH=/g/data/p66/pbd562/projects/access/apps/dummygrib/lib:$LD_RUN_PATH
export LIBRARY_PATH=/g/data/p66/pbd562/projects/access/apps/dummygrib/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=/g/data/p66/pbd562/projects/access/apps/dummygrib/lib:$LD_LIBRARY_PATH
endef
export ENVIRONMENT

scripts/environment.sh:
	@echo "$$ENVIRONMENT" > $@

src/UM : src
	#git clone accessdev.nci.org.au:/scratch/users/hxw599/submodels/UM $@
	#RN=$$RANDOM ;\
	#ssh accessdev.nci.org.au "source ~/.bash_profile ; mkdir -p /scratch/users/$$USER/tmp/$$RN/ ; cd /scratch/users/$$USER/tmp/$$RN ; svn co https://access-svn.nci.org.au/svn/cmip5/trunk_ESM1.5/submodels/UM ; rm /scratch/users/$$USER/tmp/$$RN/UM/ummodel_hg3/bin/fcm_env.ksh " ; \
	#scp -r accessdev.nci.org.au:/scratch/users/$$USER/tmp/$$RN/UM $@
	scp -r accessdev.nci.org.au:/scratch/users/hxw599/access-esm/sources/UM $@
	cp scripts/UM_exe_generator-ACCESS1.5 $@/compile/

src/mom5: src
	git clone https://github.com/OceansAus/ACCESS-ESM1.5-MOM5.git $@

bin src :
	@mkdir -p $@

bin/um_hg3.exe: src/UM bin scripts/environment.sh
	cd src/UM/compile; ./compile_ACCESS1.5

src/cice4.1: src
	scp -r accessdev.nci.org.au:/scratch/users/hxw599/access-esm/sources/cice4.1 $@

bin/cice-12p: src/cice4.1 scripts/environment.sh
	source scripts/environment.sh; cd $</compile; csh ./comp_access-cm_cice.RJ.nP-mct 12

bin/mom5xx : src/mom5 scripts/environment.sh
	source scripts/environment.sh; cd $</exp; ./MOM_compile.csh --platform=access-cm2 --type=ACCESS-CM
	cp src/mom5/exec/access-cm2/ACCESS-CM/fms_ACCESS-CM.x $@
