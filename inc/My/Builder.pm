package My::Builder;

use 5.004;
use strict;
use warnings;
use base 'Module::Build';

use PkgConfig;

sub new {
    my ($class, %args) = @_;

    my $pkg_name = 'krb5';
    my ($cflags, $ldflags, $vendor, $version) = @_;

    my $pc = PkgConfig->find($pkg_name);
    if (!$pc->errmsg) {
        $cflags  = $pc->get_cflags;
        $ldflags = $pc->get_ldflags;
        $vendor  = $pc->get_var('vendor');
        $version = $pc->pkg_version;
    } else {

        # no .pc files found, try for krb5-config
        require File::Which;

        my $krb5_config = File::Which::which('krb5-config');

        if (!$krb5_config) {
            die "Failed to get pkgconfig info or find krb5-config script!\n";
        }

        $cflags = `$krb5_config --cflags`;
        chomp $cflags;

        $ldflags = `$krb5_config --libs`;
        chomp $ldflags;

        $vendor = `$krb5_config --vendor`;
        chomp $vendor;
        $vendor = 'MIT' if $vendor eq 'Massachusetts Institute of Technology';

        $version = `$krb5_config --version`;
        chomp $version;
        $version =~ s/Kerberos 5 release //;
    }

    printf "Found %s kerberos 5 version %s\n", $vendor, $version;

    if ($vendor ne 'MIT') {
        die 'This module currently only supports MIT kerberos';
    }

    if ($cflags) {
        $args{extra_compiler_flags} = $cflags;
        print "CFLAGS: $args{extra_compiler_flags}\n";
    }

    $args{extra_linker_flags} = $ldflags;
    print "LDFLAGS: $args{extra_linker_flags}\n";

    # TODO need to be able to override travis-perl-helpers options to Devel::Cover
    # Currently we end up with coverage reports for CORE/inline.h and other system headers
    # if ($ENV{COVERAGE}) {
    #     print "Adding coverage flags\n";
    #     $args{extra_compiler_flags} .= ' --coverage';
    #     $args{extra_linker_flags}   .= ' --coverage';
    # }

    my $builder = Module::Build->new(%args);

    return $builder;
}

1;
