{
	package My::Redis;
	our $AUTOLOAD;
	sub AUTOLOAD {
		my @args = @_;
		(my $function = $AUTOLOAD) =~ s/.*://;
		unless ($function =~ /^_/) {
			print "$function\n";
			if($function =~ /^hmset$/i) {
			my $frame = 1;
			while(my ($package, $file, $line, $function) = caller($frame++)) {
				printf("Package:[%s] filename:[%s] Line:[%s] Function:[%s]\n", $package, $file, $line, $function);
			}
			}
			use Data::Dumper qw(Dumper);
			print Dumper(\@args);
		}
		goto &{"Redis::$function"};
	}
	sub DESTROY{}
}

