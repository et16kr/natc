package Complet;
use Exporter;
use strict;

## -*- Predeclare some Varable -*- ##

use vars qw($VERSION $Verbose $Switches $Have_Devel_Corestack $Curtest
            $Columns $verbose $switches $term $attribs $CWP $kwd
            @ISA @EXPORT @EXPORT_OK
           );

@ISA = qw(Exporter);
@EXPORT = qw( &set_completion $CWP $cwd);  # symbols to export by default
@EXPORT_OK = qw( &cmd_exit); 		   # symbols to export on request

# -*- Set completion for ReadLine Module -*- #

sub set_completion ($$) {
       $term = shift;
       $kwd  = shift; 
       $attribs = $term->Attribs;  
    # -*- Test Object	module	 -*- #

    $attribs->{attempted_completion_function}  =\&attempt_completion;
    $attribs->{special_prefixes} = '$@%&';
    $attribs->{completion_display_matches_hook}=\&symbol_display_match_list;
    return $attribs;
}



sub symbol_display_match_list ($$$) {
    my($matches, $num_matches, $max_length) = @_;
    map { $_ =~ s/^((\$#|[\@\$%&])?).*::(.+)/$3/; }(@{$matches});
    $term->display_match_list($matches);
    $term->forced_update_display;
}

sub attempt_completion ($$$$) {
    my ($text, $line, $start, $end) = @_;
    
    no strict qw(refs);
    if (substr($line, 0, $start) =~ m/\$([\w:]+)\s*(->)?\s*{\s*['"]?$/) {  #'
	# $foo{key, $foo->{key   
	$attribs->{completion_append_character} = '}';
	return $term->completion_matches($text,
					 \&perl_hash_key_completion_function);
    } elsif (substr($line, 0, $start) =~ m/\$([\w:]+)\s*->\s*['"]?$/) {     #' 
	# $foo->method
	$attribs->{completion_append_character} = ' ';
	return $term->completion_matches($text,
					 \&perl_method_completion_function);
    } else { # Perl symbol completion
	$attribs->{completion_append_character} = '';
	return  $term->completion_matches($text,
					  \&perl_symbol_completion_function);
    }
}

# static global variables for completion functions
use vars qw($i @matches);

sub perl_hash_key_completion_function ($$) {
    my($text, $state) = @_;
    
    if ($state) {
	$i++;
    } else {
	# the first call
	$i = 0;			# clear index
	my ($var,$arrow) = (substr($attribs->{line_buffer},
				   0, $attribs->{point} - length($text))
			    =~ m/\$([\w:]+)\s*(->)?\s*{\s*['"]?$/); # }); #'
	no strict qw(refs);
	$var = "${CWP}::$var" unless ($var =~ m/::/);
	if ($arrow) {
	    my $hashref = eval "\$$var";
	    @matches = keys %$hashref;
	} else {
	    @matches = keys %$var;
	}
	
    }
    for (; $i <= $#matches; $i++) {
	return $matches[$i] if ($matches[$i] =~ /^\Q$text/);
    }
    return undef;
}

# -*- Seach in package completion -*- #

sub _search_ISA ($) {
    my ($mypkg) = @_;
    no strict 'refs';
    my $isa = "${mypkg}::ISA";
    return $mypkg, map _search_ISA($_), @$isa;
}

# -*- Completion for subs perl -*- #

sub perl_method_completion_function ($$) {
    my($text, $state) = @_;
    
    if ($state) {
	$i++;
    } else {
	# the first call
	my ($var, $pkg, $sym, $pk);
	$i = 0;			# clear index
	$var = (substr($attribs->{line_buffer},
		       0, $attribs->{point} - length($text))
		=~ m/\$([\w:]+)\s*->\s*$/)[0];
	$pkg = ref eval (($var =~ m/::/) ? "\$$var" : "\$${CWP}::$var");
	no strict qw(refs);
	@matches = map { $pk = $_ . '::';
			 grep (/^\w+$/
			       && ($sym = "${pk}$_", defined *$sym{CODE}),
			       keys %$pk);
		     } _search_ISA($pkg);
    }
    for (; $i <= $#matches; $i++) {
	return $matches[$i] if ($matches[$i] =~ /^\Q$text/);
    }
    return undef;
}

#
#	Perl symbol name completion
#
    my ($prefix, %type, $keyword);

    sub perl_symbol_completion_function ($$) {
	my($text, $state) = @_;

	if ($state) {
	    $i++;
	} else {
	    # the first call
	    my ($pre, $pkg, $sym);
	    $i = 0;		# clear index

	    no strict qw(refs);
	    ($prefix,$pre,$pkg) = ($text =~ m/^((\$#|[\@\$%&])?(.*::)?)/);
	    @matches = grep /::$/, $pkg ? keys %$pkg : keys %::;
	    $pkg = ($CWP eq 'main' ? '::' : $CWP . '::') unless $pkg;

	    if ($pre) {		# $foo, @foo, $#foo, %foo, &foo
		@matches = (@matches,
			    grep (/^\w+$/
				  && ($sym = $pkg . $_,
				      defined *$sym{$type{$pre}}),
				  keys %$pkg));
	    } else {		# foo
		@matches = (@matches,
			    !$prefix && @{$kwd},
			    grep (/^\w+$/
				  && ($sym = $pkg . $_,
				      defined *$sym{CODE}
				      || defined *$sym{FILEHANDLE}
				     ),
				  keys %$pkg));
	    }
	}
	my $entry;
	for (; $i <= $#matches; $i++) {
	    $entry = $prefix . $matches[$i];
	    return $entry if ($entry =~ /^\Q$text/);
	}
	return undef;
    }

BEGIN{
%type = ('$' => 'SCALAR', '*' => 'SCALAR',
	 '@' => 'ARRAY' , '$#' => 'ARRAY',
	 '%' => 'HASH',
	 '&' => 'CODE'
       ); 

}

####################################################
1;
