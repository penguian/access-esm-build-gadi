
# This section contains some scripts and script-snippets for the build process
######################################

ENVFILE=scripts/environment.sh


# DEFAULT TARGET: ALL (UM, MOM5, CICE)
#########################################
all : um mom5 cice

um: bin/um_hg3.exe
mom5: bin/mom5xx
cice: bin/cice-12p
oasis: lib/oasis
gcom: lib/gcom
dummygrib: lib/dummygrib


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

# OASIS BEGIN
OASIS_MANUAL=False
if [ "$$OASIS_MANUAL" == "True" ]; then
	PBD_OASIS_DIR=$${PWD}/lib/oasis
	export FPATH=$${PBD_OASIS_DIR}/Linux/build/lib/psmile.MPI1/:$${PBD_OASIS_DIR}/Linux/build/lib/mctdir/mct:$${PBD_OASIS_DIR}/Linux/build/lib/scrip:$$FPATH
	export LIBRARY_PATH=$${PBD_OASIS_DIR}/Linux/lib:$$LIBRARY_PATH
	export LD_LIBRARY_PATH=$${PBD_OASIS_DIR}/Linux/lib:$$LD_LIBRARY_PATH
	export RPATH=$${PBD_OASIS_DIR}/Linux/lib:$$RPATH
	export LD_RUN_PATH=$${PBD_OASIS_DIR}/Linux/lib:$$LD_RUN_PATH
else
	module load oasis3-mct-local/ompi.4.0.2
fi
# OASIS END

# GCOM BEGIN
GCOM_MANUAL=False
if [ "$$GCOM_MANUAL" == "True" ]; then
	PBD_GCOM_DIR=${PWD}/lib/gcom
	export CPATH=$${PBD_GCOM_DIR}/build/include:$${CPATH}
	export LIBRARY_PATH=$${PBD_GCOM_DIR}/build/lib:$${LIBRARY_PATH}
else
	module load gcom/7.0_ompi.4.0.2
fi
# GCOM END

#NETCDF in addition to module load, adding explicit paths to netcdf.inc
export C_INCLUDE_PATH=/apps/netcdf/4.7.1/include/Intel:$$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=/apps/netcdf/4.7.1/include/Intel:$$CPLUS_INCLUDE_PATH
export CPATH=/apps/netcdf/4.7.1/include/Intel:$$CPATH
export FPATH=/apps/netcdf/4.7.1/include/Intel:$$FPATH

##DUMMYGRIB
export RPATH=$${PWD}/lib/dummygrib:$$RPATH
export LD_RUN_PATH=$${PWD}/lib/dummygrib:$$LD_RUN_PATH
export LIBRARY_PATH=$${PWD}/lib/dummygrib:$$LIBRARY_PATH
export LD_LIBRARY_PATH=$${PWD}/lib/dummygrib:$$LD_LIBRARY_PATH
endef
export ENVIRONMENT

$(ENVFILE):
	@echo "$$ENVIRONMENT" > $@

src/UM : | src
	#git clone accessdev.nci.org.au:/scratch/users/hxw599/submodels/UM $@
	#RN=$$RANDOM ;
	#ssh accessdev.nci.org.au "source ~/.bash_profile ; mkdir -p /scratch/users/$$USER/tmp/$$RN/ ; cd /scratch/users/$$USER/tmp/$$RN ; svn co https://access-svn.nci.org.au/svn/cmip5/trunk_ESM1.5/submodels/UM ; rm /scratch/users/$$USER/tmp/$$RN/UM/ummodel_hg3/bin/fcm_env.ksh " ; 
	#scp -r accessdev.nci.org.au:/scratch/users/$$USER/tmp/$$RN/UM $@
	scp -r accessdev.nci.org.au:/scratch/users/hxw599/access-esm/sources/UM $@
	cp scripts/UM_exe_generator-ACCESS1.5 $@/compile/

src/mom5: | src
	git clone https://github.com/OceansAus/ACCESS-ESM1.5-MOM5.git $@

bin src lib :
	@test -d $@ || mkdir -p $@

bin/um_hg3.exe: src/UM $(ENVFILE) lib/dummygrib | bin
	source $(ENVFILE) ; cd src/UM/compile; ./compile_ACCESS1.5

src/cice4.1: | src
	scp -r accessdev.nci.org.au:/scratch/users/hxw599/access-esm/sources/cice4.1 $@

bin/cice-12p: src/cice4.1 $(ENVFILE) | bin
	source $(ENVFILE) ; cd $</compile ; csh ./comp_access-cm_cice.RJ.nP-mct 12

bin/mom5xx : src/mom5 $(ENVFILE) | bin
	source $(ENVFILE); cd $</exp; ./MOM_compile.csh --platform=access-cm2 --type=ACCESS-CM
	cp src/mom5/exec/access-cm2/ACCESS-CM/fms_ACCESS-CM.x $@

src/dummygrib: | src
	git clone https://github.com/coecms/dummygrib.git $@

lib/dummygrib: src/dummygrib $(ENVFILE) | lib
	@source $(ENVFILE) ; cd $< ; $(MAKE)
	@test -d $@ || mkdir $@
	@cp $</libdummygrib.a $@

src/oasis: | src
	git clone -b new_modules https://github.com/coecms/oasis3-mct.git $@
	rm -rf $@/util/make_dir/config.nci
	touch $@/util/make_dir/config.nci

src/gcom: | src
	scp -r accessdev.nci.org.au:/scratch/users/hxw599/access-esm/sources/gcom $@
	sed -i '/build.target{ns}/d' $@/fcm-make/gcom.cfg
	sed -i 's/-openmp/-qopenmp/g' $@/fcm-make/machines/nci_ifort_openmpi.cfg

lib/oasis: src/oasis $(ENVFILE) | lib
ifeq (oasis,$(findstring oasis,$(MAKECMDGOALS)))
	@echo "Requested OASIS build"
	@sed -i '/OASIS_MANUAL=/c\OASIS_MANUAL=True' $(ENVFILE)
	@source $(ENVFILE) ; cd $< ; $(MAKE) -f Makefile
	@test -d $@ || mkdir $@ 
	@mv $</Linux $@/
endif

lib/gcom: src/gcom lib $(ENVFILE) lib/dummygrib
ifeq (gcom,$(findstring gcom,$(MAKECMDGOALS)))
	@echo "Requested GCOM build"
	@sed -i '/GCOM_MANUAL=/c\GCOM_MANUAL=True' $(ENVFILE)
	@source $(ENVFILE) ; cd $< ; \
	GCOM_SOURCE=$${PWD} MIRROR="" \
	ACTION="preprocess build" GCOM_MACHINE=nci_ifort_openmpi \
	DATE=x \
	fcm make -f fcm-make/gcom.cfg #-C gcom
	#@source $(ENVFILE) ; cd $< ; \
	#GCOM_MACHINE=nci_ifort_openmpi DATE=x fcm make -f fcm-make/gcom.cfg -C gcom
	test -d $@ || mkdir $@
	cp -r $</build $@
endif

.PHONY: um mom5 cice gcom oasis all
