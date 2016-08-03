#!/usr/bin/env perl6
use v6;
subset File of Str where .IO.e // die 'File not found';

my %languages =
  p => "PYTH",
  r => "RETINA",
  c => "CJAM",
  y => "JELLY",
  n => "PERL5_N",
  N => "PERL6_N",
;

my @with-path = <PYTH RETINA CJAM>;

my %interpreters =
  PYTH => "python3",
  CJAM => "java todo",
  #JELLY => "python",
  PERL5_N => "perl",
  PERL6_N => "perl6",
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
  my $interpreter = %*ENV{"{$language}_CMD"} // %interpreters{$language};
  die "No interpreter for $language" unless $interpreter;
  my $path;
  if $language eq any(@with-path) {
    $path = %*ENV{"{$language}_PATH"};
    die "No path for $language (env var: `{$language}_PATH`)" unless $path;
  }
  my $program = @program.join: "\n";
  my $proc = do given $language {
    when "PYTH" {
      run $interpreter, $path, "-c", $program, :out, :$in;
    }
    when "RETINA" {
      run $interpreter, $path, "-m", ("-e" X @program).flat, :out, :$in;
    }
    when "JELLY" {
      my ($arg1, $arg2, @) = $in.slurp-rest.lines;
      run $interpreter, 'eu', $program, $arg1, $arg2, :out;
    }
    when "PERL5_N" {
      run $interpreter, "-MList::Util", "-nE", "chomp; $program", :out, :$in;
    }
    when "PERL6_N" {
      run $interpreter, "-ne", $program, :out, :$in;
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
  print $in.slurp-rest;
}
