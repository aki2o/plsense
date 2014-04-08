on 'develop' => sub {
  requires 'Module::Install';
  requires 'Module::Install::CPANfile';
  requires 'Module::Install::AuthorTests';
  requires 'Module::Install::Repository';
};

on 'test' => sub {
  requires 'Test::More', '>= 0.98, < 2.0';
  requires 'Carton';
};

requires 'Cache::FileCache';
requires 'Class::Std' => 0.011;
requires 'Class::Std::Storable';
requires 'Config::Tiny' => 2.14;
requires 'List::AllUtils' => 0.03;
requires 'Log::Handler' => 0.76;
requires 'Module::Pluggable' => 3.9;
requires 'PPI::Document' => 1.215;
requires 'PPI::Dumper' => 1.215;
requires 'PPI::Lexer' => 1.215;
requires 'Time::Piece' => 1.20_01;
requires 'Try::Tiny' => 0.11;

