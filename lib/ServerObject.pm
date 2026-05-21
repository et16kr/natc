#!/usr/bin/perl -w
package ServerObject;

use strict;

#my $server = new ServerObject;

#$server->setProperty("db_name", "mydb");
#$server->setProperty("port_no", "20521");
#$server->setProperty("replication_port_no", "21521");
#$server->setProperty("replication_max_logfile", "300");
#$server->printProperty("db_name");
#$server->printProperty("port_no");
#$server->printProperty("replication_port_no");
#$server->printProperty("replication_max_logfile");

sub new
{
    my $class = shift;
    my $name  = shift;

    my $self = {
        name => $name,
        count => 0,
        property => {}
    };

    bless($self, $class);

    return $self;
}

sub getNumberOfProperties
{
    my $self = shift;

    return $self->{count};
}

sub existProperty
{
    my $self = shift;
    my $property = shift;

    return $self->{property}->{$property};
}

sub setProperty
{
    my $self = shift;
    my $property = shift;
    my $value = shift;

    if (!$self->existProperty($property))
    {
        $self->{count}++;
    }
    $self->{property}->{$property} = $value;
}

sub getPropertyNameByIndex
{
    my $self = shift;
    my $index = shift;

    my @key_list;
    @key_list = keys %{$self->{property}} ;

    #print "$index th property name = $key_list[$index-1]\n";

    return $key_list[$index-1];
}

sub getPropertyValueByIndex
{
    my $self = shift;
    my $index = shift;

    #print "$index th property value = $self->{property}->{$self->getPropertyNameByIndex($index)}\n";
    return $self->{property}->{$self->getPropertyNameByIndex($index)};

}

sub getPropertyValue
{
    my $self = shift;
    my $property = shift;

    return $self->{property}->{$property};
}

sub copyProperty
{
    my $self = shift;
    my $targetObject = shift;
    my @key_list;

    @key_list = keys %{$self->{property}} ;
    foreach my $name (@key_list)
    {
    	$targetObject->setProperty($name, $self->{property}->{$name});
    }
}
sub printAllProperty
{
    my $self = shift;
    my @key_list;

    print "[$self->{name}] count = $self->{count} \n";
    @key_list = keys %{$self->{property}} ;
    foreach my $name (@key_list)
    {
    	print "$name = $self->{property}->{$name}\n";
    }
}

sub printProperty
{
    my $self = shift;
    my $property = shift;
    print "$property = $self->{property}->{$property}\n";
}
1;
