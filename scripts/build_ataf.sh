#!/usr/local/bin/expect

proc abort { x } {
    puts [ format "ATAF Build Fail \[ Host: %s \] !!"  $x ]
    exit
}

if { $argc < 1 } {
     puts "usage: build_ataf hostname "
     exit
}

spawn telnet [ lindex $argv 0 ]

expect {
    "login:"                   { send "ataf\r" }
    -re "Unable to connect*"   { abort [ lindex $argv 0 ] }
    -re "could not resolve*"   { abort [ lindex $argv 0 ] }
    -re "No route*"            { abort [ lindex $argv 0 ] }
    failed                 { abort [ lindex $argv 0 ] }
    timeout                { abort [ lindex $argv 0 ] }
}

expect {
    "Password:"          { send "ataf\r" }
    failed               { abort [ lindex $argv 0 ] }
    "invalide password"  { abort [ lindex $argv 0 ] }
    timeout              { abort [ lindex $argv 0 ] }
    failed               { abort [ lindex $argv 0 ] }
    timeout              { abort [ lindex $argv 0 ] }
}

expect {
    -re "Login incorrect" { abort [ lindex $argv 0 ] }
    failed                { abort [ lindex $argv 0 ] }
    "invalide password"   { abort [ lindex $argv 0 ] }
    timeout               { abort [ lindex $argv 0 ] }
    -re "ataf*"           { exp_send "\r" }
    -re "Last login*"     { exp_send "\r" }
    connected             { exp_send "\r" }
}

# env
send "export LANG=C\r"

# remove ataf package and checkout
send "rm -rf ~/work/ataf \r"

send "svn co svn://svn.altibase.local/ataf/trunk ~/work/ataf\r"

# because there is env.sh at ataf/env, we have to check out ataf/env/ and run the env.sh.
send ". .bashrc \r"

# build ataf
send "cd ~/work/ataf; make; sh makeship.sh\r"

# install ataf
send "cd ~\r"
send "rm -rf ~/ataf_home_bck\r"
send "mv ~/ataf_home ~/ataf_home_bck\r"
send "mkdir ~/ataf_home\r"
send "cp ~/work/ataf/*.tgz ~/ataf_home\r"
send "cd ~/ataf_home; gzip -cd *.tgz | tar xvf - \r"
send "mkdir data; chmod 777 data \r"

# remove altidev4 and rebuild
send "rm -rf ~/work/altidev4\r"

# build natc script and run.
send "cd ~\r"
send "echo '\\\#!/usr/local/bin/bash' > build_natc.sh\r"
send "echo 'source .bashrc\r' >> build_natc.sh\r"
send "echo 'export ATAF_TEST_CASE=~/work/natc' >> build_natc.sh\r"
send "echo 'rm -rf ~/work/natc' >> build_natc.sh\r"
send "echo 'svn co -N svn://svn.altibase.local/natc/trunk ~/work/natc' >> build_natc.sh\r"
send "echo 'for i in `svn ls svn://svn.altibase.local/natc/trunk | grep -v TC`' >> build_natc.sh\r"
send "echo 'do' >> build_natc.sh\r"
send "echo 'svn co svn://svn.altibase.local/natc/trunk/\$i ~/work/natc/\$i' >> build_natc.sh\r"
send "echo 'done' >> build_natc.sh\r"
send "echo 'cd ~/work/natc/src/; make' >> build_natc.sh\r"
send "chmod +x ~/build_natc.sh\r"
send "~/build_natc.sh\r"

# register crontab
send "echo '0 14 * * 0,1,2,3,4,5' `pwd`/build_natc.sh > cron.txt\r"
send "crontab cron.txt\r"
send "rm -f cron.txt\r"

puts [ format "ATAF Build Success \[ Host: %s \] !!\r" [ lindex $argv 0 ] ]

# end
send "exit\r"

interact



