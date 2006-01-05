use Test::More tests=>20;
BEGIN { use_ok('Sub::ParamFrame', qw(:all)) };

    my @seasons = qw(spring summer autumn winter);

    sub actionA             # Parameter names @seasons
    {                       # case-insensitive by option 'M'=>'c'.
        my $person = shift; # first argument $person passed without a parameter name
        pfrule 'M' => 'uc', 'D' => [qw(winter SKI summer SWIM)];
        my $arg = pfload @_;
        my @L= map $arg->{$_}||'?',@seasons;
        ['+',$person,@L];
    }

    sub actionB      # Parameter names (case-insensitive, shortable up to length 2)
    {                #      sp[ring], su[mmer], au[tumn], wi[nter]
        my $person = shift; # first argument passed without a name
        pfrule
            'M' =>    # match any left substring of a season-name with legth
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
        ['-',$person,map $arg->{$_}||'?',@seasons];
    }

    sub test
    {
        my ($in,$out) = @_;
        my ($choice,@I) = @$in;
        my $msg = sprintf '%8s :',shift @I;
        while ( my ($k,$v)= splice @I,0,2 )
        {
            $msg .= sprintf '%7s=>%-7s',$k,$v;
        };

        @I = @$in; shift @I;

        return is_deeply(actionA(@I), $out,'+'.$msg) if $choice eq 'A';
        return is_deeply(actionB(@I), $out,'x'.$msg) if $choice eq 'B';
        ok(0,sprintf('First argument od test=%s, neither A nor B!'.qq(\n), $choice));
    }

    sub TESTDATA ();

    {
        my $TD = TESTDATA;
        while ( my ($ia,$oa) = splice @$TD,0,2 )
        {
             test $ia,$oa;
        }
    }

    sub TESTDATA ()
    {
      [
        [qw( A Alice Spring run Autumn ride )],
        [qw( + Alice run SWIM ride SKI )],

        [qw( B Alice Spri run AU ride )],
        [qw( - Alice run WATERJUMP ride SNOWBOARD )],

        [qw( A Ann spring sing SUMMER dive AuTumn study )],
        [qw( + Ann sing dive study SKI )],

        [qw( B Ann spr sing SUM dive Au study )],
        [qw( - Ann sing dive study SNOWBOARD )],

        [qw( A Iris AUTUMN travel WINTER shop Spring marry summer bike )],
        [qw( + Iris marry bike travel shop )],

        [qw( B Iris AUT travel WIN shop Spring marry summer bike )],
        [qw( - Iris marry bike travel shop )],

        [qw( B Eric )],
        [qw( - Eric BIKE WATERJUMP EAT SNOWBOARD )],

        [qw( B Mary Summer swim )],
        [qw( - Mary BIKE swim EAT SNOWBOARD )],

        [qw( A Fred Wi sleep SPR wakeup )],
        [qw( + Fred ? SWIM ? SKI )],

        [qw( B Fred Wi sleep SPR wakeup )],
        [qw( - Fred wakeup WATERJUMP EAT sleep )],
      ]
    }