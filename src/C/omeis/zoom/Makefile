export DEFINES
export FINK_INCLUDE
install:
	-install -d include lib bin
	cd libsys; make install
	cd libpic; make install
	cd zoom; make install

clean:
	-rm -fr include lib bin
	cd libsys; make clean
	cd libpic; make clean
	cd zoom; make clean
