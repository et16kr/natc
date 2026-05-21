cd $ATC_HOME
find TC -name "*.ts" > $ATC_HOME/TL/ts.map

cd $ATC_HOME
find TC -type d ! -name CVS > $ATC_HOME/dir.map
