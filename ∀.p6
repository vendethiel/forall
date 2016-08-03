#!/usr/bin/env perl6
use v6;
subset File of Str where .IO.e // die 'File not found';

my %languages =
  p => "PYTH",
  r => "RETINA",
  c => "CJAM",
;

my %interpreters =
  PYTH => "python3",
;

sub parse-programs(@lines is copy) {
  gather {
    my %current-program = type => '';
    for |@lines, '' {
      my $type = ~(s/(.)// // '');
      if $type eq %current-program<type> {
        %current-program<lines>.push: $_;
      } else {
        take %current-program.clone if %current-program<type>;
        %current-program = :$type, lines => [$_];
      }
    }
  }
}

sub run-program($type, @program, $in) {
  my $language = %languages{$type} // die "No such language: $type";
  my $interpreter = %*ENV{"{$language}_CMD"} // %interpreters{$language} // die "No interpreter for $language";
  my $path = %*ENV{"{$language}_PATH"} // die "No path for $language (env var: `{$language}_PATH`)";
  my $proc = do given $language {
    when "PYTH" {
      run $interpreter, $path, "-c", @program.join("\n"), :out, :$in;
    }
    when "RETINA" {
      run $interpreter, $path, "-m", ("-e" X @program).flat, :out, :$in;
    }
    default { die "Language not yet configured: $language" } 
  }
  die "Process failed to execute: `$interpreter`" if $proc.exitcode;
  $proc.out;
}

sub MAIN(File $file, Str :$retina?, Str :$pyth?) {
  my @programs = parse-programs(lines slurp $file);
  my $in = $*IN;
  for @programs -> % (:$type, :@lines) {
    $in = run-program($type, @lines, $in);
  }
  say $in.slurp-rest;
}
