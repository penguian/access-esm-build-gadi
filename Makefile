src/UM : src
	#@ssh accessdev.nci.org.au "mkdir -p /scratch/users/$$USER/um; cd /scratch/users/$$USER/um; svn co https://access-svn.nci.org.au/svn/cmip5/trunk_ESM1.5/submodels/UM"
	#@rsync -r accessdev.nci.org.au:/scratch/users/$$USER/um src/
	@echo "Please run this command on accessdev: \n svn co https://access-svn.nci.org.au/svn/cmip5/trunk_ESM1.5/submodels/UM"
	@echo Then copy the contents of that repository here.
	@echo 'ssh accessdev.nci.org.au "mkdir -p /scratch/users/$$USER/um; cd /scratch/users/$$USER/um; svn co https://access-svn.nci.org.au/svn/cmip5/trunk_ESM1.5/submodels/UM"'
	@echo 'rsync -r accessdev.nci.org.au:/scratch/users/$$USER/um src/'
	false

bin src :
	@mkdir -p $@


bin/um_hg3.exe: src/UM/ummodel_hg3/bin/fcm_env.ksh bin
	cd src/UM/compile; ./UM_exe_generator-ACCESS1.5

src/UM/ummodel_hg3/bin/fcm_env.ksh : /g/data/p66/pbd562/test/t47-hxw/jan20/4.0.2/trunk_ESM1.5/submodels/UM/ummodel_hg3/fcm_env.sh src/UM
	ln -s $< $@

