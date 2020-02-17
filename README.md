# ACCESS ESM Build Environment for GADI

## Prerequisits

- Need passwordless login on accessdev from gadi

## Usage

    git clone 
    make

### Make targets:

* oasis: Compiles the OASIS-MCT library in lib/oasis, and enables that version for future compiles
* gcom: Compiles the GCOM library in lib/gcom, and enables that version for future compiles
* um: Build the UM to bin/um_hg3.exe
* mom: Build MOM5 to bin/mom5xx
* cice: Build CICE4.1 to bin/cice
* all: same as um mom cice

### Build environment:

A file scripts/environment.sh is created automatically by the makefile, it can be edited if required.
This file sets up the build environment for all submodules.

