#!/usr/local/bin/expect

proc abort { x } {
    puts [ format "Host: %s ATAF Test Fail!!"  $x ]
    exit
}

if { $argc < 3 } {
     puts "usage: check_ataf hostname userid userpasswd"
     exit
}

spawn telnet [ lindex $argv 0 ]

expect {
    "login:"                   { send "[ lindex $argv 1 ]\r" }
    -re "Unable to connect*"   { abort [ lindex $argv 0 ] }
    -re "could not resolve*"   { abort [ lindex $argv 0 ] }
    -re "No route*"            { abort [ lindex $argv 0 ] }
    failed                 { abort [ lindex $argv 0 ] }
    timeout                { abort [ lindex $argv 0 ] }
}

expect {
    "Password:"          { send "[ lindex $argv 2 ]\r" }
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
    -re "[ lindex $argv 1 ]*"           { exp_send "\r" }
    -re "Last login*"      { exp_send "\r" }
    connected              { exp_send "\r" }
}

#env
send "export LANG=C\r"

# test ataf
send "ataf stop\r"
expect {
    failed             { exp_send "\r" } 
    timeout            { exp_send "\r" } 
    -re "command not*" { exp_send "\r" } 
    -re "initialized"  { exp_send "\r" } 
    -re "Error"        { exp_send "\r" } 
}

send "sleep 3\r"
send "ataf start \$STAF_HOME/bin/STAF.cfg\r"

expect {
    failed              { abort [ lindex $argv 0 ] }
    timeout             { abort [ lindex $argv 0 ] }
    -re "command not*"  { abort [ lindex $argv 0 ] }
    -re "initialized"   { puts [ format "Host: %s ATAF Test Success!!\r"  [ lindex $argv 0 ] ] }
    -re "Error"         { abort [ lindex $argv 0 ] }
}

send "ataf stop\r"

# end
send "exit\r"
interact
