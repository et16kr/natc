#!/usr/local/bin/expect

proc abort { x } {
    puts [ format "Set User Env Fail \[ Host: %s \] !!"  $x ]
    exit
}

if { $argc < 4 } {
     puts "usage: build_ataf_userenv.sh hostname os_name\[linux|solaris|aix|dec|hpux|hpux-ia64\] userid userpasswd"
     exit
}

spawn telnet [ lindex $argv 0 ]

expect {
    "login:"                   { send "[ lindex $argv 2 ]\r" }
    -re "Unable to connect*"   { abort [ lindex $argv 0 ] }
    -re "could not resolve*"   { abort [ lindex $argv 0 ] }
    -re "No route*"            { abort [ lindex $argv 0 ] }
    failed                 { abort [ lindex $argv 0 ] }
    timeout                { abort [ lindex $argv 0 ] }
}

expect {
    "Password:"          { send "[ lindex $argv 3 ]\r" }
    failed               { abort [ lindex $argv 0 ] }
    "invalide password"  { abort [ lindex $argv 0 ] }
    timeout              { abort [ lindex $argv 0 ] }
    failed               { abort [ lindex $argv 0 ] }
    timeout              { abort [ lindex $argv 0 ] }
}

expect {
    -re "Login incorrect*" { abort [ lindex $argv 0 ] }
    failed                 { abort [ lindex $argv 0 ] }
    "invalide password"    { abort [ lindex $argv 0 ] }
    timeout                { abort [ lindex $argv 0 ] }
    -re "[ lindex $argv 2 ]*"           { exp_send "\r" }
    -re "Last login*"      { exp_send "\r" }
    connected              { exp_send "\r" }
}

# set locale
send "export LANG=C\r"

# set OS_NAME
send "grep -v 'OS_NAME' .bashrc | sed 's/.bashrc://g' >  tmp.txt \r"
send "echo 'export OS_NAME=[ lindex $argv 1]' >> tmp.txt\r"
send "cp tmp.txt .bashrc\r"

# set ATAF_TEST_CASE
send "grep -v 'ATAF_TEST_CASE' .bashrc | sed 's/.bashrc://g' > tmp.txt \r"
send "echo 'export ATAF_TEST_CASE=\$HOME/work/natc' >> tmp.txt\r"
send "echo 'export ATC_HOME=\$ATAF_TEST_CASE' >> tmp.txt\r"
send "cp tmp.txt .bashrc\r"

# set LD_LIBRARY_PATH
send "grep -v 'LD_LIBRARY_PATH' .bashrc | sed 's/.bashrc://g' > tmp.txt \r"
send "echo 'export LD_LIBRARY_PATH=~ataf/work/natc/lib:/usr/local/lib:\$STAF_HOME/lib:/lib:/usr/lib:\$LD_LIBRARY_PATH' >> tmp.txt\r"
send "echo 'export LD_LIBRARY_PATH=\$ALTIBASE_HOME/lib:\$LD_LIBRARY_PATH' >> tmp.txt\r"
send "cp tmp.txt .bashrc\r"

# set LD_LIBRARY_PATH_64
send "grep -v 'LD_LIBRARY_PATH64' .bashrc | sed 's/.bashrc://g' > tmp.txt \r"
send "echo 'export LD_LIBRARY_PATH64=~ataf/work/natc/lib:/usr/local/lib:\$STAF_HOME/lib:/lib:/usr/lib:\$LD_LIBRARY_PATH64' >> tmp.txt\r"
send "echo 'export LD_LIBRARY_PATH64=\$ALTIBASE_HOME/lib:\$LD_LIBRARY_PATH64' >> tmp.txt\r"

send "cp tmp.txt .bashrc\r"

# set LIBPATH
send "grep -v 'LIBPATH' .bashrc | sed 's/.bashrc://g' > tmp.txt \r"
send "echo 'export LIBPATH=~ataf/work/natc/lib:/usr/local/lib:\$STAF_HOME/lib:/lib:/usr/lib:\$LIBPATH' >> tmp.txt\r"
send "cp tmp.txt .bashrc\r"

# set PATH
send "grep -v '~ataf/work/natc/bin' .bashrc | sed 's/.bashrc://g' >  tmp.txt \r"
send "echo 'export PATH=~ataf/ataf_home/bin:~ataf/work/natc/bin:\$PATH' >> tmp.txt\r"
send "cp tmp.txt .bashrc\r"

# end
send "exit\r"

interact
