#!/usr/bin/perl -w

use DateTime;
use DateTime::Format::DateParse;
use DateTime::Format::Strptime qw( );

my($date) = DateTime::Format::DateParse->parse_datetime('2012/10/01');
my($end) = DateTime->now;

my($file_format) = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d.csv' );
my($year_format) = DateTime::Format::Strptime->new( pattern => '%Y' );

my(%packages) = ();

while ($date < $end)
{
	my($csv_file) = $file_format->format_datetime($date);
	my($year) = $year_format->format_datetime($date);

	print "Downloading $csv_file ...\n";
	system("wget -c -t 0 --timeout=60 --waitretry=60 http://cran-logs.rstudio.com/$year/$csv_file.gz");
	system("gunzip $csv_file.gz");
	
	if (! -e $csv_file)
	{
		print "Failed to download $csv_file\n";
		next;
	}

	open(my $fh, '<', $csv_file) or die "Cannot read file '$csv_file' [$!]\n";

	my($iline) = 0;
	my($ifield) = -1;

	while (my $line = <$fh>)
	{
		chomp $line;
		my(@fields) = split(/,/, $line);
	
		# Get the index of column containing packages names.
		if ($iline == 0)
		{
			$ifield = 0;
			foreach $field (@fields)
			{
				if ($field eq "\"package\"")
				{
					last;
				}
				$ifield++;
			}
			if ($ifield == scalar(@fields))
			{
				die "Cannot find the packages names column\n";
			}
			$iline++;
			next;
		}

		# Track packages
		if (not exists($packages{$fields[$ifield]}))
		{
			$packages{$fields[$ifield]} = 1;
		}
		else
		{
			$packages{$fields[$ifield]} += 1;
		}
	}

	foreach my $package (sort { $packages{$b} <=> $packages{$a} } keys %packages)
	{
		print $package . " " . $packages{$package} . "\n";
	}

	$date->add(days => 1);   # move along to next day
}

