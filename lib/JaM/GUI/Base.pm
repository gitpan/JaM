# $Id: Base.pm,v 1.11 2001/08/14 21:12:50 joern Exp $

package JaM::GUI::Base;

use strict;
use Carp;
use Data::Dumper;
use Cwd;
use Date::Manip;
use JaM::Config;
use JaM::GUI::HTMLSurface;

my $CONFIG_OBJECT;
my %COMPONENTS;

sub new {
	my $type = shift;
	my %par = @_;
	
	my  ($dbh) = @par{'dbh'};

	my $self = {
		dbh => $dbh,
	};
	
	if ( not defined $CONFIG_OBJECT and $dbh ) {
		$CONFIG_OBJECT = JaM::Config->new ( dbh => $dbh );
	}
	
	return bless $self, $type;
}

my @WEEKDAYS = ( 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' );

# return database handle
sub dbh 		{ shift->{dbh}			}
sub htdocs_dir		{ return "lib/JaM/htdocs" }

# get/set component objects
sub comp {
	my $self = shift;
	my ($name, $object) = @_;
	return $COMPONENTS{$name} = $object if @_ == 2;
	confess "unknown component '$name'"
		if not defined $COMPONENTS{$name};
	return $COMPONENTS{$name};
}

# get/set configuration parameters
sub config {
	my $self = shift;
	my ($name, $value) = @_;

	if ( @_ == 2 ) {
		$value = $CONFIG_OBJECT->set_value ($name, $value);
	} else {
		$value = $CONFIG_OBJECT->get_value ($name);
	}

	return $value;
}

# get config object
sub config_object {
	$CONFIG_OBJECT;
}

# restart program (needed during initalization process)
sub restart_program {
	exec ("bin/jam.pl", @ARGV);
}

# convert a unix timestamp to date format
sub format_date {
	my $self = shift;
	my %par = @_;
	my ($sent_time, $date, $nice) = @par{'time','date','nice'};

	# if $date is given, format to unix time
	if ( $date ) {
		$sent_time = UnixDate ($date, "%s");
	}

	# format sent date
	my $sent_nice;
	my @st = localtime($sent_time);
	my @tt = localtime(time);
	
	if ( not $nice ) {
		# full date
		return sprintf (
			"%s %02d.%02d.%04d %02d:%02d",
			$WEEKDAYS[$st[6]],
			$st[3],$st[4]+1,$st[5]+1900,$st[2], $st[1]
		);
	}
	
	if ( $st[7] == $tt[7] ) {
		# from today: only time
		$sent_nice = sprintf (
			"%02d:%02d",
			$st[2], $st[1]
		);
	} elsif ( $sent_time > time - 432000 ) {
		# less than 5 days: Weekday and time
		$sent_nice = sprintf (
			"%s %02d:%02d",
			$WEEKDAYS[$st[6]],
			$st[2], $st[1]
		);
	} else {
		# full date
		$sent_nice = sprintf (
			"%02d.%02d.%04d %02d:%02d",
			$st[3],$st[4]+1,$st[5]+1900,$st[2], $st[1]
		);
	}
	
	return $sent_nice;
}

sub show_file_dialog {
	my $self = shift;
	my %par = @_;
	my  ($dir, $filename, $cb, $title, $confirm) =
	@par{'dir','filename','cb','title','confirm'};
	
	my $cwd = cwd;
	chdir ( $dir );
	
	# Create a new file selection widget
	my $dialog = new Gtk::FileSelection( $title );

	# Connect the ok_button to file_ok_sel function
	$dialog->ok_button->signal_connect(
		"clicked",
		sub { $self->cb_commit_file_dialog (@_, $confirm) },
		$cb, $dialog
	);

	# Connect the cancel_button to destroy the widget
	$dialog->cancel_button->signal_connect(
		"clicked", sub { $dialog->destroy }
	);

	$dialog->set_filename( $filename );
	$dialog->set_position ( "mouse" );
	$dialog->show();
	
	chdir ($cwd);

	1;
}

sub cb_commit_file_dialog {
	my $self = shift;
	my ($button, $cb, $dialog, $confirm) = @_;
	
	my $filename = $dialog->get_filename();
	
	if ( -f $filename and $confirm ) {
		my $confirm = Gtk::Dialog->new;
		my $label = Gtk::Label->new ("Overwrite existing file '$filename'?");
		$confirm->vbox->pack_start ($label, 1, 1, 0);
		$confirm->border_width(10);
		$confirm->set_title ("Confirmation");
		$label->show;
		my $ok = Gtk::Button->new ("Ok");
		$confirm->action_area->pack_start ( $ok, 1, 1, 0 );
		$ok->can_default(1);
		$ok->grab_default;
		$ok->signal_connect( "clicked", sub { $confirm->destroy; &$cb($filename) } );
		$ok->show;
		my $cancel = Gtk::Button->new ("Cancel");
		$confirm->action_area->pack_start ( $cancel, 1, 1, 0 );
		$cancel->signal_connect( "clicked", sub { $confirm->destroy } );
		$cancel->show;
		
		$confirm->set_position ("mouse");
		$confirm->set_modal (1);
		$confirm->show;

		$dialog->destroy;
	} else {
		&$cb($filename);
		$dialog->destroy;
	}

	1;
}

sub help_window {
	my $self = shift;
	my %par = @_;
	my ($file, $title) = @par{'file','title'};
	
	my $win = new Gtk::Window;
	$win->set_title( "Help: $title" );
	$win->set_usize ( 420, 350 );
	$win->border_width(0);
	$win->position ('center');
	$win->signal_connect("destroy", sub { $win->destroy } );

	my $vbox = Gtk::VBox->new (0,0);
	$vbox->show;	

	my $sw = new Gtk::ScrolledWindow(undef, undef);
	$sw->set_policy('automatic', 'automatic');

	my $html = JaM::GUI::HTMLSurface->new (
		image_dir => $self->htdocs_dir,
	);


	$HELP::HEADER = qq{
		<html><body bgcolor="white">
		<h1>JaM Help: $title</h1>
		<hr>
		<p>
	};
	$HELP::FOOTER = qq{
		</body>
		</html>
	};

	$html->show_eval (
		file => "help/$file"
	);

	my $widget = $html->widget;
	$sw->show;
	$sw->add($widget);

	$vbox->pack_start($sw, 1, 1, 0);

	$win->add ($vbox);
	$win->show;

	1;	
	
}

sub message_window {
	my $self = shift;
	my %par = @_;
	my ($message) = @par{'message'};
	
	my $dialog = Gtk::Dialog->new;

	my $label = Gtk::Label->new ($message);
	$dialog->vbox->pack_start ($label, 1, 1, 0);
	$dialog->border_width(10);
	$dialog->set_title ("JaM Message");
	$dialog->set_default_size (250, 150);
	$label->show;

	my $ok = Gtk::Button->new ("Ok");
	$dialog->action_area->pack_start ( $ok, 1, 1, 0 );
	$ok->signal_connect( "clicked", sub { $dialog->destroy } );
	$ok->show;

	$dialog->set_position ("center");
	$dialog->show;

	1;	
	
}

#---------------------------------------------------------------------
# Debugging stuff
# 
# Setzen/Abfragen des Debugging Levels. Wenn als Klassenmethode
# aufgerufen, wird das Debugging klassenweit eingeschaltet. Als
# Objektmethode aufgerufen, wird Debugging nur für das entsprechende
# Objekt eingeschaltet.
#
# Level:	0	Debugging deaktiviert
#		1	nur aktive Debugging Ausgaben
#		2	Call Trace, Subroutinen Namen
#		3	Call Trace, Subroutinen Namen + Argumente
#
# Debuggingausgaben erfolgen im Klartext auf STDERR.
#---------------------------------------------------------------------

sub debug_level {
	my $thing = shift;
	my $debug;
	if ( ref $thing ) {
		$thing->{debug} = shift if @_;
		$debug = $thing->{debug};
	} else {
		$JaM::DEBUG = shift if @_;
		$debug = $JaM::DEBUG;
	}
	
	if ( $debug ) {
		$JaM::DEBUG::TIME = scalar(localtime(time));
		print STDERR
			"--- START ------------------------------------\n",
			"$$: $JaM::DEBUG::TIME - DEBUG LEVEL $debug\n";
	}
	
	return $debug;
}

#---------------------------------------------------------------------
# Klassen/Objekt Methode
# 
# Gibt je nach Debugginglevel entsprechende Call Trace Informationen
# aus bzw. tut gar nichts, wenn Debugging abgeschaltet ist.
#---------------------------------------------------------------------

sub trace_in {
	my $thing = shift;
	my $debug = $JaM::DEBUG;
	$debug = $thing->{debug} if ref $thing and $thing->{debug};
	return if $debug < 2;

	# Level 1: Methodenaufrufe
	if ( $debug == 2 ) {
		my @c1 = caller (1);
		my @c2 = caller (2);
		print STDERR "$$: TRACE IN : $c1[3] (-> $c2[3])\n";
	}
	
	# Level 2: Methodenaufrufe mit Parametern
	if ( $debug == 3 ) {
		package DB;
		my @c = caller (1);
		my $args = '"'.(join('","',@DB::args)).'"';
		my @c2 = caller (2);
		print STDERR "$$: TRACE IN : $c[3] (-> $c2[3])\n\t($args)\n";
	}
	
	1;
}

sub trace_out {
	my $thing = shift;
	my $debug = $JaM::DEBUG;
	$debug = $thing->{debug} if ref $thing and $thing->{debug};
	return if $debug < 2;

	my @c1 = caller (1);
	my @c2 = caller (2);
	print STDERR "$$: TRACE OUT: $c1[3] (-> $c2[3])";

	if ( $debug == 2 ) {
		print STDERR " DATA: ", Dumper(@_);
	} else {
		print STDERR "\n";
	}
	
	1;
}

sub dump {
	my $thing = shift;
	my $debug = $JaM::DEBUG;
	$debug = $thing->{debug} if ref $thing and $thing->{debug};
	return if not $debug;	

	if ( @_ ) {
		print STDERR Dumper(@_);
	} else {
		print STDERR Dumper($thing);
	}
}

sub debug {
	my $thing = shift;
	my $debug = $JaM::DEBUG;
	$debug = $thing->{debug} if ref $thing and $thing->{debug};
	return if not $debug;	

	my @c1 = caller (1);
	print STDERR "$$: DEBUG    : $c1[3]: ", join (",", @_), "\n";
	1;
}

sub gdk_color {
	my $self = shift;
	my ($html_color) = @_;
	
	$html_color =~ s/^#//;
	
	my ($r, $g, $b) = ( $html_color =~ /(..)(..)(..)/ );

	my $cmap = Gtk::Gdk::Colormap->get_system();
	my $color = {
		red   => hex($r) * 256,
		green => hex($g) * 256,
		blue  => hex($b) * 256,
	};
	
	if ( not $cmap->color_alloc ($color) ) {
		warn ("Couldn't allocate color $html_color");
	}
	
	return $color;
}
	

1;
