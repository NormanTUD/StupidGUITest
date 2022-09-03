#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Term::ANSIColor;

sub timeout ($);

my %options = (
	starturl => '',
	regex_error_page => 'rquery',
	x11disabledregex => 'Die Seite ist deaktiviert, weil der x11_debugging_mode aktiv ist'
);

analyze_args(@ARGV);

main();

sub _help {
	my $exit_code = shift // 0;
	print <<EOF;
--help						This help
--starturl="https://starturl.com/"		The pages that should be visited once there is a x11-test-disabled page
--regex_error_page="errorpageregex"		A regex that recognizes whether the error page is reached or not
--x11disabledregex="x11_debugging_mode aktiv"	A regex that checks whether a certain feature was disabled for x11-testing,
						if found, go to starturl
EOF
	exit $exit_code;
}

sub analyze_args {
	for (@_) {
		if(/^--starturl=(.*)$/) {
			$options{starturl} = $1;
		} elsif (/^--regex_error_page=(.*)$/) {
			$options{regex_error_page} = $1;
		} else {
			warn "Unknown parameter `$_`\n";
			_help(1);
		}
	}
}

sub msg ($) {
	my $var = shift;
	print color("yellow").$var.color("reset")."\n";
}

sub myqx {
	my $command = shift;
	exit 0 if(-e "/tmp/kill_x11_test");
	print "$command\n";
	my $res = qx($command);
	if(wantarray()) {
		return ($res, $? << 8);

	} else {
		return $res;
	}
}

sub mysystem {
	my $command = shift;
	exit 0 if(-e "/tmp/kill_x11_test");
	print "$command\n";
	system($command);
	return $? << 8;
}

sub main {
	unlink "/tmp/kill_x11_test";

	msg "Move your mouse to the upper left corner of the area that should be clicked in and press <enter>";
	<STDIN>;
	my $upper_left = get_mouse();

	msg "Move your mouse to the lower right corner of the area that should be clicked in and press <enter>";
	<STDIN>;
	my $lower_right = get_mouse();

	timeout 2;

	set_mouse($upper_left->[0], $upper_left->[1]);
	click();

	while (1) {
		if(screen_contains_error($options{regex_error_page})) {
			mysystem(q#pico2wave --lang en-GB --wave /tmp/Test.wav "Warning, I believe I have found an error"; play /tmp/Test.wav; rm /tmp/Test.wav#);
			die("ERROR found!");
		}

		if($options{starturl} && get_full_text() =~ m#(?:(?:was not found on this server)|(?:$options{x11disabledregex}))#) {
			press_key('ctrl+l');
			timeout 2;
			mysystem("xdotool type --delay 200 $options{starturl}");
			press_enter();
			timeout 2;
			set_mouse($upper_left->[0], $upper_left->[1]);
			click();
		} else {
			move_mouse_randomly_in_area($upper_left, $lower_right);
			if(rand() >= 0.6) {
				if(rand() >= 0.5) {
					if(rand() >= 0.9) {
						doubleclick();
					} else {
						click();
					}
				}
			}

			if(rand() >= 0.8) {
				for (0 .. int(rand(200))) {
					my @possibilites = (1 .. 4);
					my $rand = $possibilites[rand @possibilites];

					if($rand == 1) {
						scroll_right();
					} elsif($rand == 2) {
						scroll_left();
					} elsif($rand == 3) {
						scroll_down();
					} elsif($rand == 4) {
						scroll_up();
					}
				}
			} elsif(rand() >= 0.2) {
				for(1 .. int(rand(30))) {
					go_to_next_input_field();
				}
			}

			press_some_random_keys();
			press_enter();
		}
	}
}

sub go_to_next_input_field {
	print "Use this extension for this task: https://addons.mozilla.org/en-US/firefox/addon/fox-input/";
	press_key('alt+j');
}

sub scroll_up {
	myqx("xdotool key Up");
}

sub scroll_down {
	myqx("xdotool key Down");
}

sub scroll_left {
	myqx("xdotool key Left");
}

sub scroll_right {
	myqx("xdotool key Right");
}

sub set_mouse {
	my ($x, $y) = @_;

	$x = int($x);
	$y = int($y);

	my $command = "xdotool mousemove $x $y";
	mysystem($command);
}

sub get_mouse {
	my $command = qq#xdotool getmouselocation | sed -E "s/ screen:0 window:[^ ]*|x:|y://g"#;
	my $res = myqx($command);
	if($res =~ m#^(\d+)\s+(\d+)$#) {
		return [$1, $2];
	} else {
		die("ERROR with $res");
	}
}

sub rand_range {
	my ($min, $max) = @_;
	my $num = $min + rand($max - $min);
	return $num;
}

sub move_mouse_randomly_in_area {
	my ($upper_left, $lower_right) = @_;

	my $random_x = rand_range($upper_left->[0], $lower_right->[0]);
	my $random_y = rand_range($upper_left->[1], $lower_right->[1]);
	set_mouse($random_x, $random_y);
	click(0);
}

sub doubleclick {
	mysystem("xdotool click 1 click 1");
	timeout 2;
}

sub click {
	my $sleep = shift // 1;
	mysystem("xdotool click 1");
	timeout $sleep;
}

sub press_key {
	my $key = shift;
	my $command = "xdotool key $key";
	mysystem($command);
}

sub press_enter {
	press_key('KP_Enter');
	timeout 2;
}

sub press_some_random_keys {
	my @keys = ('a' .. 'z', 0 .. 9, 'a' .. 'z', 0 .. 9, 'a' .. 'z', 0 .. 9, map { 'shift+'.$_ } ('a' .. 'z') );

	for (0 .. rand_range(10, 100)) {
		my $key = $keys[rand @keys];
		press_key($key);
	}
}

sub screen_contains_error {
	my $search_for = shift // 'dier';

	my $text = get_full_text();
	print "--> $text";

	if($text =~ m#$search_for#) {
		return 1;
	}

	return 0;
}

sub get_full_text {
	mark_all_copy();
	my $text = get_clipboard();
	click(0);
	return $text;
}

sub mark_all_copy {
	myqx("xdotool key ctrl+a");
	myqx("xdotool key ctrl+c");
}

sub get_clipboard {
	my $clipboard = myqx("xclip -o -selection clipboard");
	return $clipboard;
}

sub timeout ($) {
	my $wait = shift;

	while ($wait) {
		warn "Waiting $wait seconds...\n";
		$wait--;
		sleep 1;
	}
}
