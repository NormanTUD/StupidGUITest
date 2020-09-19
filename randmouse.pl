#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Term::ANSIColor;

main(@ARGV);

sub msg ($) {
	my $var = shift;
	print color("yellow").$var.color("reset")."\n";
}

sub myqx {
	my $command = shift;
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
	print "$command\n";
	system($command);
	return $? << 8;
}

sub main {
	my $error_regex = shift // 'dier';
	msg "Move your mouse to the upper left corner of the area that should be clicked in and press <enter>";
	<>;
	my $upper_left = get_mouse();

	msg "Move your mouse to the lower right corner of the area that should be clicked in and press <enter>";
	<>;
	my $lower_right = get_mouse();

	my $i = 5;
	while ($i) {
		print "Sleeping $i seconds\n";
		sleep 1;
		$i--;
	}

	set_mouse($upper_left->[0], $upper_left->[1]);
	click();

	while (1) {
		if(screen_contains_error($error_regex)) {
			mysystem(q#pico2wave --lang en-GB --wave /tmp/Test.wav "Warning, I believe I have found an error"; play /tmp/Test.wav; rm /tmp/Test.wav#);
			die("ERROR found!");
		}

		move_mouse_randomly_in_area($upper_left, $lower_right);
		if(rand() >= 0.6) {
			if(rand() >= 0.5) {
				for (1 .. int(rand(100))) {
					press_tab();
				}
			} else {
				if(rand() >= 0.9) {
					doubleclick();
				} else {
					click();
				}
			}
		}

		if(rand() >= 0.9) {
			my @possibilites = (1 .. 4);
			my $rand = $possibilites[rand @possibilites];

			if($rand == 1) {
				for (0 .. int(rand(100))) {
					scroll_right();
				}
			} elsif($rand == 2) {
				for (0 .. int(rand(100))) {
					scroll_left();
				}
			} elsif($rand == 3) {
				for (0 .. int(rand(100))) {
					scroll_down();
				}
			} elsif($rand == 4) {
				for (0 .. int(rand(100))) {
					scroll_up();
				}
			}

		}

		press_some_random_keys();
		press_enter();

	}
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
	sleep 2;
}

sub click {
	my $sleep = shift // 1;
	mysystem("xdotool click 1");
	sleep $sleep;
}

sub press_key {
	my $key = shift;
	my $command = "xdotool key $key";
	mysystem($command);
}

sub press_tab {
	press_key('Tab');
}

sub press_enter {
	press_key('KP_Enter');
	sleep 2;
}

sub press_some_random_keys {
	my @keys = ('Tab', 'a' .. 'z', 0 .. 9, 'a' .. 'z', 0 .. 9, 'a' .. 'z', 0 .. 9, map { 'shift+'.$_ } ('a' .. 'z') );

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
