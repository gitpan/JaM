# $Id: Init.pm,v 1.1 2001/08/11 14:37:26 joern Exp $

package JaM::GUI::Init;

use JaM::GUI::Database;
use JaM::Database;

use strict;

sub db_configuration {
	my $type = shift;

	Gtk->init;

	my $db_gui = JaM::GUI::Database->new;
	$db_gui->in_initialization(1);
	$db_gui->build_configuration_window;

	Gtk->main;
}

sub check_schema_version {
	my $type = shift;
	my %par = @_;
	my ($dbh) = @par{'dbh'};

	my $db = JaM::Database->load;
	
	if ( not $db->schema_ok ( dbh => $dbh ) ) {
		$type->db_configuration if $db->database_version == 0;

		Gtk->init;
		my $db_gui = JaM::GUI::Database->new ( dbh => $dbh );
		$db_gui->in_initialization(1);
		$db_gui->build_schema_update_window ( db => $db, dbh => $dbh );
		Gtk->main;
	}

	1;
}

1;
