#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Spec;

my $script_path = abs_path(__FILE__);
my ( undef, $script_dir ) = File::Spec->splitpath($script_path);
chdir $script_dir or die "Could not chdir to $script_dir: $!";

my @awesome_files = glob 'AWESOME*';
die "No AWESOME* files found in $script_dir\n" if not @awesome_files;

open my $fh, '<', 'AWESOME.md' or die "Could not open AWESOME.md: $!";

my %seen;
while ( my $line = <$fh> ) {
    next if $line !~ m{^\s*[*-]\s+.*\((https://github\.com/[^)]+)\)};

    my $url = $1;
    $url =~ s/[?#].*\z//;
    $url =~ s{\.git\z}{};
    $url =~ s{/+\z}{};

    my ($repo) = $url =~ m{/([^/]+)\z};
    next if not defined $repo;
    next if $seen{$repo}++;

    my $target = File::Spec->catdir('..', $repo);
    print "working on $target\n";
    if ( not -d $target ) {
        print "  Skipping $target: directory does not exist\n";
        next;
    }

    my $target_path = abs_path($target);
    my $source_path = abs_path($script_dir);
    if ( defined $target_path and defined $source_path and $target_path eq  $source_path ) {
        print "  Skipping $target: current directory\n";
        next;
    }

    for my $file (@awesome_files) {
        my $destination = File::Spec->catfile( $target, $file );
        if (-e $destination) {
            print "  copy $file to $destination\n";
            copy( $file, $destination ) or die "Could not copy $file to $destination: $!";
        }
    }
}

close $fh or die "Could not close AWESOME.md: $!";
