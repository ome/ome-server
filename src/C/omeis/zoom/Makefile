install:
	-mkdir include lib bin
	cd libsys; make DEFINES='$(DEFINES)' install
	cd libpic; make DEFINES='$(DEFINES)' install
	cd zoom; make DEFINES='$(DEFINES)' install

clean:
	-rm -fr include lib bin
	cd libsys; make clean
	cd libpic; make clean
	cd zoom; make clean
