package TFSh;
$^W=1;
# pragmata
use strict;

# load modules
use Exporter ;
use Event;
# load Completing function
use Complet qw ( set_completion $CWP);

use vars qw ( @ISA @EXPORT @EXPORT_OK
    $PS1  $PS2  $INPUTRC  $HOSTNAME
    $LOGNAME $CMD $HISTFILE
    $term $attribs $complet 
    $IN $OUT $ERR
    );

@ISA = qw( Exporter Complet);

@EXPORT = qw();  		# symbols to export by default
# Export by demand 
@EXPORT_OK = qw( cmd_exit $CMD ); 	# symbols to export on request

use File::Basename;
use Term::ReadLine;

# -*- Local Varable -*- # 
my ($curly,$bracket,$strict);

#my @keyword;
sub  new {
    my ($class) = shift;
    my $self = {
	HistSize    => 128,		      	# History Size 256 by default
	HistFile    => './rc/.perlsh_history',	# History File
	Strict      => 1,                     	# Strict  by Default
	InputStream => \*STDIN ,	      	# Input stream 
    OutputStream=> \*STDOUT,	      	# Output Stream
    ErrorStream => \*STDERR,	      	# Output Stream
    ## -*- Some Internal VArs    -*- ##
	result	    => [],
    ## -*- Overide  by invocator -*- ##
        @_,					# Override defaults	
	};
    bless $self,ref $class || $class;
	
    *HISTFILE = \$self->{HistFile};
    *IN	      = \$self->{InputStream};
    *OUT      = \$self->{OutputStream};
    *ERR      = \$self->{ErrorStream};
    *term     = \$self->{Terminal};
    $strict = $self->{Strict} ? '' : 'no strict;';
    $self->init_readline;
  return $self;	
}

###################
### Init Section ##
###################

# init readline
sub init_readline ($) {
my $self  = shift;
    $term = new Term::ReadLine(prompt($PS1)) unless $term;
    $term->newTTY($IN,$OUT);
    $term->stifle_history($self->{HistSize});
    $term->callback_handler_install(prompt($PS1), \&processLine);
## -*- Disable AutoHistory -*- ##
#    $term->MinLine(undef);

    $term->stifle_history($self->{HistSize});
    if (-f $self->{HistFile}) 
	 {
	     $term->ReadHistory($HISTFILE)
	     or warn "perlsh: cannot read history file: $!\n";
      } # end if

# New Method
     use Complet::perl qw( $kwd); 
     set_completion($term,$kwd);
# store output buffer in a scalar (for print)
    $attribs = $term->Attribs;

# install STDIN handler
Event->io(
	  desc   => 'io Test FrSh',	# description;
	  fd     => $term->IN,          # handle;
	  poll   => 'r',	        # wait for income;
	  repeat => 1,                  # keep alive after events;
	  cb     => sub {&{$attribs->{'callback_read_char'}}()}, #callback;
	 );

# Var Event control handler 
Event->var( 
	    pool   => 'w',
	    var	   => \$CMD,
	    desc   => 'cmd Test FrSh',           # description;
	    prio   => 5,                         # low priority;
	    repeat => 1,                         # keep alive after events;
	    cb     => sub {
		   	$self->{result} = eval("$strict;package $CWP;$CMD;");
			use strict;
			if ($@) { print $ERR "Error: $@\n"; return; }
#			printer (@result);
			$CWP = $1 if ($CMD =~ /^\s*package\s+([\w:]+)/);
			        $term->rl_set_prompt(prompt($PS1));	        
				$term->modifying;
				$term->redisplay;
	}) ;

} # End of init_readline


# -* Process Line  *- #

my ($BuffLine)='';

# handle a line completely read
sub processLine
 {
  # get line
  my ($line)=@_;
  chomp $line;
  # anyhing to process?
  if ($line=~/^exit\s*(\d*)$/)
   { &cmd_exit($1) 
   }
  else
   {
     # do something
     if ($line=~/.*;$/)  
	  {
	   $BuffLine.="\n" if $BuffLine;	  
       $CMD= $BuffLine.$line;
       $term->add_history($CMD);
       $term->rl_set_prompt(prompt($PS1));
	   $BuffLine = '';
   	  }
	  else
	  {
	   $BuffLine.="\n" if $BuffLine;	  
	   $BuffLine.=$line ;
	   $term->rl_set_prompt(prompt($PS2)) unless ($line  eq '');
	  };
#!   $term->add_history($line) if $line ne '';
   };# end if
 }

sub cmd_exit ($)  {
     my $exit_code = shift||0;
        $term->WriteHistory($HISTFILE) 
		or print $ERR "perlsh: cannot write history file: $!\n";
     print $OUT "\n";
     $term->callback_handler_remove();
     $_->cancel for Event::all_watchers;
   exit  $exit_code;
}

sub prompt($) {
    local($_) = shift;
    # if reference to a subroutine return the return value of it
    return &$_ if (ref($_) eq 'CODE');
    # \h: hostname, \u: username, \w: package name, \!: history number
    s/\\h/$HOSTNAME/g;
    s/\\u/$LOGNAME/g;
    s/\\w/$CWP/g;
    $attribs?s/\\!/$attribs->{history_base} + $attribs->{history_length}/eg:s/\\!/0/eg;
    $_;
}



BEGIN{
	$PS1	    = '\w[\!]$ ',		# Prompt Prefix
	$PS2 	    = '> ',			# Prompt Syffix
	$INPUTRC    = (($ENV{HOME}||		# Resurse File 
		((getpwuid($<))[7])))."/.perlshrc";
	$HOSTNAME   =  $ENV{HOSTNAME},		# HOSTNAME from Enviroment
	$LOGNAME    =  $ENV{LOGNAME},		# LOGNAME
	$CWP	    =  'main',

## -*- Syntax Counters -*- ##
        $curly      = 0; 	# Curly   balans '}{'
	$bracket    = 0;	# Bracket balans ']['
}

1;

