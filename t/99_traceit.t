{

	BEGIN {
		$ENV{RIAK_TRACE} = 999;
	}

	package Foo;
	use Riak::Light::TraceIt;
	use Moo;

	our $foo_dumper_called = 0;
	our $baz_dumper_called = 0;

	sub foo :TraceIt(1, 
		dumper => sub { $foo_dumper_called = 1; '...' }, 
		omit_throw => 1,
		__should_trace => sub { 0 }
		) 
	{
		return	1;
	}

	sub bar :TraceIt(){
		return 2;
	}

	sub baz :TraceIt(2,
		now => sub { time },
		omit_return => 1,
		dumper_indent => 1,
		dumper_terse => 0,
		dumper => sub { $baz_dumper_called = 1; '...' }, 
		show_file_line => 0,
		__should_trace => sub { 1 },
		)
	{
		die 'exception';
	}

	package main;
	use Test::More tests => 5;
	use Test::Exception;

	is( Foo->new->foo(1), 1, 'should return one');
	is( $Foo::foo_dumper_called, 0, 'should not trace');

	is( Foo->new->bar(1), 2, 'should return two');

	throws_ok { Foo->new->baz(1) } qr/exception/, 'should die';
	is( $Foo::baz_dumper_called, 1, 'should trace');
}
