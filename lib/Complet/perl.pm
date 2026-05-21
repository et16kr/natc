package Complet::perl;

use Exporter;
use strict;

## -*- Predeclare some Varable -*- ##

use vars qw( $KeyWord  @ISA @EXPORT @EXPORT_OK );

@ISA = qw(Exporter);
@EXPORT = qw( $kwd); 	# symbols to export on request

*kwd=\$KeyWord;

$KeyWord =[qw(
    chomp chop chr crypt hex index lc lcfirst
    length oct ord pack q qq
    reverse rindex sprintf substr tr uc ucfirst
    y
    m pos quotemeta s split study qr

    abs  atan2  cos  exp  hex  int  log  oct  rand  sin  sqrt  srand

    pop  push  shift  splice  unshift


    grep  join  map  qw    reverse  sort  unpack

    delete  each  exists  keys  values

    binmode  close  closedir  dbmclose  dbmopen  die  eof  fileno  flock  
    format  getc  print  printf  read  readdir  rewinddir  seek  seekdir  
    select syscall sysread syswrite tell  telldir  truncate  warn  write

    pack  read  syscall  sysread  syswrite  unpack  vec


    chdir  chmod  chown  chroot  fcntl  glob  ioctl  link  lstat  mkdir
    open  opendir  readlink  rename  rmdir stat  symlink  sysopen  umask
    unlink  utime

    caller  continue  die  do  dump  eval  exit  goto  last  next  redo
    return  sub  wantarray

    caller  import  local  my  package  use


    defined dump eval formline local my reset scalar undef wantarray


    alarm exec fork getpgrp getppid getpriority kill pipe qx setpgrp
    setpriority  sleep  system  times  wait  waitpid


    do  import  no  package  require  use


    bless  dbmclose  dbmopen  package  ref  tie  tied  untie  use


    accept bind connect getpeername getsockname getsockopt listen recv send
    setsockopt  shutdown  socket  socketpair


    msgctl msgget msgrcv msgsnd semctl semget semop shmctl shmget shmread shmwrite


    endgrent  endhostent  endnetent  endpwent  getgrent  getgrgid getgrnam getlogin
    getpwent  getpwnam  getpwuid  setgrent  setpwent


    endprotoent  endservent  gethostbyaddr  gethostbyname  gethostent  getnetbyaddr
    getnetbyname getnetent getprotobyname getprotobynumber getprotoent getservbyname
    getservbyport  getservent  sethostent  setnetent  setprotoent  setservent

    gmtime  localtime  time  times
)];


1;
