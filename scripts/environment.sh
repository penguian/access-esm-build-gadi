module purge
#from AMIP umui
module use ~access/modules
module load intel-compiler/2019.3.199
module load netcdf/4.7.1
module load openmpi/4.0.2
module load fcm/2019.09.0
module load gcom/7.0_ompi.4.0.2
module load oasis3-mct-local/ompi.4.0.2
module load um 
module load dummygrib 
#NETCDF in addition to module load, adding explicit paths to netcdf.inc
export C_INCLUDE_PATH=/apps/netcdf/4.7.1/include/Intel:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=/apps/netcdf/4.7.1/include/Intel:$CPLUS_INCLUDE_PATH
export CPATH=/apps/netcdf/4.7.1/include/Intel:$CPATH
export FPATH=/apps/netcdf/4.7.1/include/Intel:$FPATH
SYSTEMDIR=$MY_PATH/../../

##DUMMYGRIB
export RPATH=/g/data/p66/pbd562/projects/access/apps/dummygrib/lib:$RPATH
export LD_RUN_PATH=/g/data/p66/pbd562/projects/access/apps/dummygrib/lib:$LD_RUN_PATH
export LIBRARY_PATH=/g/data/p66/pbd562/projects/access/apps/dummygrib/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=/g/data/p66/pbd562/projects/access/apps/dummygrib/lib:$LD_LIBRARY_PATH
