@rem = '--*-Perl-*--

@echo off

set PERL_PATH=c:\progra~2\tools\git\bin
if "%PERL_PATH%" == "" goto endofperl

set PATH=.;%PATH%;%PERL_PATH%

perl -x -S %0 %*
goto endofperl

@rem ';


#!/usr/bin/perl


{
	foreach my $filename (@ARGV) {
		next unless isPidstatFile($filename);
		
		my ($header, $processes, $empty_contents) = preprocess($filename);
		my $logs = createLogs($filename, $processes, $empty_contents);

		(my $outputfile = $filename) =~ s/\.pidstat/.csv/;

		write2CSV($header, $logs, $empty_contents, $outputfile);
	}
}


sub createLogs {
	my ($filename, $processes, $empty_contents) = @_;

	open IN, "$filename";
	my $logs = loadLogs($IN, $processes, $empty_contents);
	close IN;

	return $logs;
}


sub loadLogs {
	my ($IN, $processes, $empty_contents) = @_;
	my $logs = {};

	while (<IN>) {
		next unless /^\s+\d/;

		s/^\s+//;
		s/$//;
		
		my ($time, $pid, @data) = split /\s+/;
		pop @data;

		unless ($logs->{$time}) {
			my %processData = map { $_ => $empty_contents } keys %$processes;
			$logs->{$time} = \%processData;
		}
		
		$logs->{$time}->{$pid} = \@data;
	}

	return $logs;
}


sub isPidstatFile {
	my ($filename) = @_;

	return $filename =~ m/\.pidstat$/ ? 1 : 0;
}


sub preprocess {
	my ($filename)  = @_;

	my $contents    = [];
	my $processes   = {};

	open IN, "$filename";
	doPreprocess($IN, $contents, $processes);
	close IN;

	my $header     = generateHeader($contents, $processes);
	my $empty_data = createEmptyContents($contents);

	return ($header, $processes, $empty_data);
}


sub doPreprocess {
	my ($IN, $contents, $processes) = @_;

	while (<IN>) {
		if (/^#/) {
			last if ( @$contents && %$processes );

			obtainContents($_, $contents);
			next;
		}

		if (/^\s+\d/) {
			obtainProcesses($_, $processes);
		}
	}
}


sub obtainContents {
	my ($row, $contents) = @_;

	$row =~ s/^#\s+//;
	$row =~ s/$//;

	my ($time, $pid, @data) = split /\s+/, $row;
	pop @data;
	
	@$contents = @data;
}


sub obtainProcesses {
	my ($row, $processes) = @_;

	s/^\s+//;
	s/$//;

	my ($time, $pid, @data) = split /\s+/;
	my $command = pop @data;
	$processes->{$pid} = $command;
}


sub generateHeader {
	my ($contents, $processes) 	= @_;
	my @captions 			   	= ("Time");

	foreach my $pid (sort {$a <=> $b} keys %$processes) {
		foreach my $content (@$contents) {
			push @captions, "$content\[$processes->{$pid}($pid)\]";
		}
	}

	return join ',', @captions;
}


sub createEmptyContents {
	my ($contents) = @_;
	my $empty_data = [];

	foreach (@$contents) {
		push @$empty_data, "";
	}

	return $empty_data;
}


sub write2CSV {
	my ($header, $logs, $empty_data, $outputfile) = @_;

	$output = loopByTimes($logs, $empty_data);
	unshift @$output, "$header\n";

	open(OUT, ">$outputfile");
	print OUT @$output;
	close OUT;
}


sub loopByTimes {
	my ($logs, $empty_data) = @_;
	my $output              = [];

	foreach my $time (sort keys %$logs) {
		my $line = [];
		push @$line, $time;

		loopByProcessId($line, $empty_data, %{$logs->{$time}});
		$csvline = join ',', @$line;
		push @$output, "$csvline\n";
	}

	return $output;
}


sub loopByProcessId {
	my ($line, $empty_data, %processData) = @_;

	foreach my $pid (sort {$a <=> $b} keys %processData) {
		$data = $processData{$pid};

		if (@$data) {
			push @$line, @$data;

			next;
		}

		push @$line, @$empty_data;
	}
}


1;
__END__


:endofperl
