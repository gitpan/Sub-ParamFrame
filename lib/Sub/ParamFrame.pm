package Sub::ParamFrame;

use 5.008007;
use strict; no strict 'refs';
use Carp;
use Sub::ParamLoader; # <= uses Tie::Hash::KeysMask

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( pfrule pfload ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = '0.01';

########## private ###########

my %register = ();

########## public ###########

sub pfrule
{
    my $calltop = [caller(1)];
    croak 'pfrule must be called inside a subroutine'
        unless $calltop;
    my $subname = $calltop->[3] ;
    $register{$subname} = Sub::ParamLoader->new (@_)
        unless exists $register{$subname};
    # about calling syntax  see  package Sub::ParamLoader
}

sub pfload
{
    my $thisSub = [caller(1)]->[3];
    $register{$thisSub} = Sub::ParamLoader->new # use empty frame
        unless exists $register{$thisSub};

    $register{$thisSub}->load(@_);
}

1;

__END__

=head1 NAME

Sub::ParamFrame - Supply key alias and defaults of named arguments.

=head1 SYNOPSIS

    use Sub::ParamFrame ':all';

    sub myFunc
    {
        # Define the rule how named arguments shell be processed
        pfrule
          'D' => [...,Name(i)=>DefVal(i),...], # assign default key-value  association.
          'M' => [ sub {...}, P(1),...P(k) ];  # keys mask function and fixed arguments

        # access a certain count of positional arguments here
        my @PARGS = splice @_,0,N;

        # Load named arguments. That is create a hash according to arguments
        # passed to pfrule. This hash also contains default arguments

        my $arg = pfload @_;

        # access argument or default of name NAME
        do_something_with $arg->{NAME};
        ......
        # or likewise access key NAME, in addition erase it from $arg
        do_something_with delete $arg->{NAME};
        .......
        # could also be used in list context accessing multiple arguments ..
        ($v1,$v2,...) = delete @$arg{NAME1,NAME2,...};
        ....
    }   ##myFunc

=head1 DESCRIPTION

A couple of modules already deal with named parameters and default values,
see L<Sub::Parameters>,L<Sub::NamedParams>,L<Sub::Declaration>,L<Perl6::Parameters>.

This solution pursues another scope of usability, covers distinct features
and uses another syntactic approach.

Named parameters are identified by a hash built from the argument vector C<@_>.
The generation and behavior of this hash will be controlled by a rule.
If one subroutine C<myFunc()> uses such a rule, this rule  appears as a command
within the subroutine's body.
The rule lays down one ore both of two properties:

1. a name-value-association of defaults and 2. an alias mapping for argument names.

Once this rule is passed by call of C<pfrule> from the first invocation of
C<myFunc>, the generation of the hash by the C<pfload> function shell follow
this rule at once and during future calls.

C<pfrule> appears before  C<pfload> and will be executed only once, only
when the calling subroutine runs first time.

Two named optional arguments are defined for C<pfrule>, neither must be present.

=head3 Arguments of C<pfrule>

        'D' => [...,Name(i)=>DefVal(i),...]

Defines a default key-value-association. C<pfload> stores this
association before arguments usually from C<@_> advance and may override some
default values.

        'M' => $mask                      where  $mask = sub {...}
        'M' => [ $mask, P(1),...P(m) ]    or           = \&fmask

Keys mask function and optionally fixed arguments.
If 'M' is omitted C<pfload> shall return just a hash.
If 'M' is present it causes C<pfload> to return a hash tied to class
C<Tie::Hash::KeysMask> such that each access to the hash triggers a
key translation:

         $k   =>   $mask->($k,P(1),...P(m))

Instead of a CODE C<'M'=E<gt>$mask> could take one of the following particular values

        'M' => 'lc'   or  'M' => 'uc'   or  'M' => \%T

        which will be translated into a CODE as follows

        'lc' => sub { lc $_[0] }        # omit case of character distinction
        'uc' => sub { uc $_[0] }        # with 'uc' or 'lc' translations
        \%T  => sub { exists $T{$_[0]} ? $T{$_[0]} : $_[0]}
                                        # hash %T defines aliases

Contrary to other approaches to named arguments,
one may choose freely the position of the first named argument
within C<@_>. Any amount of C<@_> may be shifted onto positional parameters
before the command C<pfload @_> takes the remaining pairs of key=>value.
Of course arguments different from  C<@_> are also allowed behind C<pfload>.

=head1 DEPENDENCIES

C<Sub::ParamFrame> is not a class, however it relies on a class package
C<Sub::ParamLoader> which inherits from C<Tie::Hash::KeysMask>.

=head1 CAVEATS

As described in L<Tie::Hash::KeysMask> one must take care, that the mask function
(specified by 'M'=>) fit to some restriction.

=head1 EXAMPLE

    use Sub::ParamFrame ':all';

    my @seasons = qw(spring summer autumn winter);

    sub actionA             # Parameter names @seasons
    {                       # case-insensitive by option 'M'=>'c'.
        my $person = shift; # first argument $person passed without a parameter name
        pfrule 'M' => 'uc', 'D' => [qw(winter SKI summer SWIM)];
        my $arg = pfload @_;
        my $pname = sprintf '+%12s does ',$person;
        my $actions = join ', ',map sprintf('%s:%s',$_,$arg->{$_}),@seasons;
        $pname.$actions."\n";
    }

    sub actionB      # Parameter names (case-insensitive, shortable up to length 2)
    {                #      sp[ring], su[mmer], au[tumn], wi[nter]
        my $person = shift; # first argument passed without a name
        pfrule
            'M' =>    # match any left substring of a season-name with length
            sub       # at least 2, ignoring case of characters
            {
                my $ikl  = lc(shift);      my $ikl2 = substr $ikl,0,2;
                my $res  = {qw(sp spring su summer au autumn wi winter)}->{$ikl2};
                return undef unless
                ( defined $res)  && ($ikl eq substr($res,0,length $ikl));
                $res;
            },
        'D' => [qw(wi SNOWBOARD spr BIKE su WATERJUMP aut EAT)];

        my $arg = pfload @_;
        my $pname = sprintf '-%12s does ',$person;
        my $actions = join ', ',map sprintf('%s:%s',$_,$arg->{$_}),@seasons;
        $pname.$actions."\n";
    }

    # For ease visual distinction default values were chosen in uppercase
    print "Default values uppercase ('D'=>[.. 'winter'=>'SKI'...]), others lowercase!\n";
    print '-'x74,"\n";
    print actionA qw(Alice Spring run Autumn ride);
    print actionB qw(Alice Spri   run AU     ride);
    print actionA qw(Ann spring sing SUMMER dive AuTumn study);
    print actionB qw(Ann spr    sing SUM    dive Au     study);
    print actionA qw(Iris AUTUMN travel WINTER shop Spring marry summer bike);
    print actionB qw(Iris AUT    travel WIN    shop Spring marry summer bike);

=head1 AUTHOR

Josef SchE<ouml>nbrunner E<lt>j.schoenbrunner@onemail.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 by Josef SchE<ouml>nbrunner
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut