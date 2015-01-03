package Complete::Riap;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Complete;

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(complete_riap_url);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Riap-related completion routines',
};

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
        ci => {
            summary => 'Whether to do case-insensitive search',
            schema  => 'bool*',
        },
        map_case => {
            schema => 'bool',
        },
        exp_im_path => {
            schema => 'bool',
        },
        type => {
            schema => ['str*', in=>['function','package']], # XXX other types?
            summary => 'Filter by entity type',
        },
        riap_client => {
            schema => 'obj*',
        },
    },
    result_naked => 1,
};
sub complete_riap_url {
    require Complete::Path;

    my %args = @_;

    my $word = $args{word} // ''; $word = '/' if !length($word);
    $word = "/$word" unless $word =~ m!\A/!;
    my $ci          = $args{ci} // $Complete::OPT_CI;
    my $map_case    = $args{map_case} // $Complete::OPT_MAP_CASE;
    my $exp_im_path = $args{exp_im_path} // $Complete::OPT_EXP_IM_PATH;
    my $type = $args{type} // '';

    my $starting_path;
    my $result_prefix = '';
    if ($word =~ s!\A/!!) {
        $starting_path = '/';
        $result_prefix = '/';
    } elsif ($word =~ s!\Apl:/!/!) {
        $starting_path = 'pl:';
        $result_prefix = 'pl:';
    } else {
        return [];
    }

    my $res = Complete::Path::complete_path(
        word => $word,
        ci => $ci, map_case => $map_case, exp_im_path => $exp_im_path,
        list_func => sub {
            my ($path, $intdir, $isint) = @_;

            state $default_pa = do {
                require Perinci::Access;
                Perinci::Access->new;
            };
            my $pa = $args{riap_client} // $default_pa;

            $path = "/$path" unless $path =~ m!\A/!;
            my $riap_res = $pa->request(list => $path, {detail=>1});
            return [] unless $riap_res->[0] == 200;
            my @res;
            for my $ent (@{ $riap_res->[2] }) {
                next unless $ent->{type} eq 'package' ||
                    (!$type || $type eq $ent->{type});
                push @res, $ent->{uri};
            }
            \@res;
        },
        starting_path => $starting_path,
        result_prefix => $result_prefix,
        is_dir_func => sub { }, # not needed, we already suffixed "dir" with /
    );

    {words=>$res, path_sep=>'/'};
}

1;
#ABSTRACT:

=head1 SYNOPSIS

 use Complete::Riap qw(complete_riap_url);
 my $res = complete_riap_url(word => '/Te', type=>'package');
 # -> {word=>['/Template/', '/Test/', '/Text/'], path_sep=>'/'}


=cut
