
# This section contains some scripts and script-snippets for the build process
######################################

ENVFILE=./environment.sh

# DEFAULT TARGET: ALL (UM, MOM5, CICE)
#########################################
all : um mom5 mppnccombine cice

um: bin/um_hg3.exe
um_dbg: bin/um_hg3_dbg.exe
mom5: bin/mom5xx
mppnccombine: bin/mppnccombine
cice: bin/cice-12p
oasis: lib/oasis
gcom: lib/gcom
dummygrib: lib/dummygrib

srcs: src/UM src/mom5 src/cice4.1

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
export OASIS_ROOT=$${PWD}/lib/oasis
export OASIS_INCLUDE_DIR=$${OASIS_ROOT}/include
export OASIS_LIB_DIR=$${OASIS_ROOT}/lib
export FPATH=$${OASIS_INCLUDE_DIR}:$$FPATH
export LIBRARY_PATH=$${OASIS_LIB_DIR}:$$LIBRARY_PATH
export LD_LIBRARY_PATH=$${OASIS_LIB_DIR}:$$LD_LIBRARY_PATH
export RPATH=$${OASIS_LIB_DIR}:$$RPATH
export LD_RUN_PATH=$${OASIS_LIB_DIR}:$$LD_RUN_PATH
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


bin src lib :
	@test -d $@ || mkdir -p $@

# This section is about getting the sources for the libraries and the submodules
#------------------------------------

src/oasis: | src
	git clone -b access-esm1.5 https://github.com/ACCESS-NRI/oasis3-mct.git $@
	rm -rf $@/util/make_dir/config.nci
	touch $@/util/make_dir/config.nci

src/dummygrib: | src
	git clone https://github.com/ACCESS-NRI/dummygrib.git $@

src/gcom: | src
	rm -rf $@
	git clone -b access-esm1.5 git@github.com:ACCESS-NRI/GCOM4 $@
	sed -i '/build.target{ns}/d' $@/fcm-make/gcom.cfg
	sed -i 's/-openmp/-qopenmp/g' $@/fcm-make/machines/nci_ifort_openmpi.cfg

src/UM : | src
	rm -rf $@
	git clone -b access-esm1.5 git@github.com:ACCESS-NRI/UM_v7 $@
	cp patch/UM_exe_generator-ACCESS1.5 $@/compile/

src/mom5: | src
	git clone -b access-esm1.5 https://github.com/ACCESS-NRI/MOM5.git $@

src/cice4.1: | src
	git clone -b access-esm1.5 https://github.com/ACCESS-NRI/cice4.git $@
	sed -i 's/\([[:space:]]*setenv CPLLIBDIR\).*$$/\1 $$OASIS_LIB_DIR/' $@/compile/comp_access-cm_cice.RJ.nP-mct
	sed -i 's/\([[:space:]]*setenv CPLINCDIR\).*$$/\1 $$OASIS_INCLUDE_DIR/' $@/compile/comp_access-cm_cice.RJ.nP-mct
	rm -f $@/compile/environs.raijin.nci.org.au ; touch $@/compile/environs.raijin.nci.org.au
	cp patch/Macros.Linux.raijin.nci.org.au-mct $@/bld


# This section describes how to compile the libraries.
# -----------------------------

# DummyGRIB is a library that doesn't do anything, but is needed as
# UM and GCOM want to include a library called "GRIB" even though it
# does nothing here.
lib/dummygrib: src/dummygrib $(ENVFILE) | lib
	@source $(ENVFILE) ; cd $< ; $(MAKE)
	@test -d $@ || mkdir $@
	@cp $</libdummygrib.a $@

lib/oasis: src/oasis $(ENVFILE) | lib
	@sleep 1 ; source $(ENVFILE) ; cd $< ; $(MAKE) -f Makefile
	@test -d $@ || mkdir $@
	@mkdir -p $@/include
	@cp $</Linux/build/lib/scrip/*.mod $</Linux/build/lib/psmile.MPI1/*.mod $</Linux/build/lib/mct/*.mod $@/include
	@rm -rf $@/lib
	@cp -r $</Linux/lib $@

lib/gcom: src/gcom lib $(ENVFILE) lib/dummygrib
ifeq (gcom,$(findstring gcom,$(MAKECMDGOALS)))
	@echo "Requested GCOM build"
	@sed -i '/GCOM_MANUAL=/c\GCOM_MANUAL=True' $(ENVFILE)
	@source $(ENVFILE) ; cd $< ; \
	GCOM_SOURCE=$${PWD} MIRROR="" \
	ACTION="preprocess build" GCOM_MACHINE=nci_ifort_openmpi \
	DATE=x \
	fcm make -f fcm-make/gcom.cfg #-C gcom
	test -d $@ || mkdir $@
	cp -r $</build $@
endif


# Finally, the submodel binaries
# ---------------------------------

bin/um_hg3.exe: src/UM $(ENVFILE) lib/dummygrib lib/oasis | bin
	source $(ENVFILE) ; cd src/UM/compile; ./compile_ACCESS1.5

bin/um_hg3_dbg.exe: src/UM $(ENVFILE) lib/dummygrib lib/oasis | bin
	source $(ENVFILE) ; cd src/UM/compile; ./compile_ACCESS1.5 debug

bin/cice-12p: src/cice4.1 $(ENVFILE) lib/oasis | bin
	source $(ENVFILE) ; cd $</compile ; csh ./comp_access-cm_cice.RJ.nP-mct 12

bin/mom5xx : src/mom5 $(ENVFILE) lib/oasis | bin
	source $(ENVFILE) ; cd $</exp ; csh ./MOM_compile.csh --platform=access-cm2 --type=ACCESS-CM --no_environ
	cp src/mom5/exec/access-cm2/ACCESS-CM/fms_ACCESS-CM.x $@

bin/mppnccombine : src/mom5 bin/mom5xx | bin
	cp src/mom5/bin/mppnccombine.access-cm2 $@

.PHONY: um mom5 mppnccombine cice gcom oasis all srcs
