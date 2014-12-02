package Complete::Riap;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(complete_riap_url);

$SPEC{complete_riap_url} = {
    v => 1.1,
    summary => 'Complete Riap URL',
    description => <<'_',

Currently only support local Perl schemes (e.g. `/Pkg/Subpkg/function` or
`pl:/Pkg/Subpkg/`).

_
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        type => {
            schema => ['str*', in=>['function','package']], # XXX other types?
            summary => 'Filter by entity type',
        },
    },
    result_naked => 1,
};
sub complete_riap_url {
    my %args = @_;

    my $word = $args{word} // ''; $word = '/' if !length($word);
    my $type = $args{type} // '';

    my $scheme;
    if ($word =~ m!\A/!) {
        $scheme = '';
    } elsif ($word =~ s!\Apl:/!/!) {
        $scheme = 'pl';
    } else {
        return [];
    }

    my ($pkg, $leaf) = $word =~ m!(.*/)(.*)!;
    state $pa = do {
        require Perinci::Access;
        Perinci::Access->new;
    };

    my $riap_res = $pa->request(list => $pkg, {detail=>1});
    return [] unless $riap_res->[0] == 200;

    my @res;
    for my $ent (@{ $riap_res->[2] }) {
        next unless $ent->{type} eq 'package' ||
            (!$type || $type eq $ent->{type});
        next unless index($ent->{uri}, $leaf) == 0;
        push @res, "$pkg$ent->{uri}";
    }

    # put scheme back on
    if ($scheme) {
        for (@res) { $_ = "$scheme:$_" }
    }

    {words=>\@res, path_sep=>'/'};
}

1;
#ABSTRACT: Riap-related completion routines

=head1 SYNOPSIS

 use Complete::Riap qw(complete_riap_url);
 my $res = complete_riap_url(word => '/Te', type=>'package');
 # -> {word=>['/Template/', '/Test/', '/Text/'], path_sep=>'/'}


=head1 TODO

'ci' option (this should perhaps be implemented in
L<Perinci::Access::Schemeless>?).

=cut
