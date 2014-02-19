use strict;
use warnings;
use Test::More;

plan skip_all => "requires WorePAN" unless eval "use WorePAN 0.03; 1";
my @tests = (
  ['S/SE/SEANO/sepia-0.61.tgz', 'Xref.pm', 'Sepia::Xref', undef],
);

for my $test (@tests) {
  my ($path, $pmfile, $package, $version) = @$test;
  note "downloading $path...";

  my $worepan = WorePAN->new(
    root => 'tmp',
    no_network => 0,
    use_backpan => 1,
    cleanup => 0,
    no_indices => 1,
    files => [$path],
  );

  note "parsing $path...";

  $worepan->walk(callback => sub {
    my $dir = shift;
    my $file = $dir->file($pmfile);
    my $parser = Parse::PMFile->new;

    my ($info, $errs);
    eval {
      local $SIG{ALRM} = sub { die "timeout\n" };
      alarm 30;
      ($info, $errs) = $parser->parse($file);
      alarm 0;
    };
    ok !$@ && ref $info eq ref {} && $info->{$package}{version} eq $version, "returned no version";
    ok !$@ && ref $errs eq ref {} && $errs->{$package}{parse_version}, "returned invalid version";
    note $@ if $@;
    note explain $info;
    note explain $errs;
  });
}

done_testing;
