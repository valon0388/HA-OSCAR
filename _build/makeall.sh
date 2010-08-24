rm *.deb
cd haoscar-binaries/
./debmake
mv haoscar-core.deb ..
cd ../haoscar-devel/
./debmake
mv haoscar-dev.deb ..
cd ../haoscar-libraries/
./debmake
mv haoscar-lib.deb ..
cd ../haoscar-utils/
./debmake
mv haoscar-util.deb ..
