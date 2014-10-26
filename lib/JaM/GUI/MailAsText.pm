# $Id: MailAsText.pm,v 1.2 2001/08/10 20:12:26 joern Exp $

package JaM::GUI::MailAsText;

@ISA = qw ( JaM::GUI::HTMLSurface );

use strict;
use Carp;

sub widget 	    { confess "widget called" }
sub image_dir 	    { confess "image_dir called"    }

sub handle	    { confess "handle called" }
sub image_pool	    { return {} }
sub url_in_focus    { confess "url_in_focus called"  }

sub gtk_attachment_popup    { confess "gtk_attachment_popup called"  }

sub text	    { my $s = shift; $s->{text}
		      = shift if @_; $s->{text}		}
sub quote	    { my $s = shift; $s->{quote}
		      = shift if @_; $s->{quote}	}

sub new {
	my $type = shift;
	my %par = @_;
	my ($quote) = @par{'quote'};
	
	my $self = bless {
		text => "",
		quote => $quote
	}, $type;

	return $self;
}

sub begin {
	my $self = shift;
	$self->text("");
	1;
}

sub end {
	my $self = shift;
	1;
}

sub write {
	my $self = shift;
	my @data = @_;

	foreach my $line ( @data ) {
		$line =~ s!</tr>!\n!g;
		$line =~ s!<br>!\n!g;
		$line =~ s!<p>!\n\n!g;
		$line =~ s!<.*?>!!g;
		$line =~ s!&lt;!<!g;
		$line =~ s!&nbsp;! !g;
		$line =~ s!\n!\n> !g if $self->quote;
		$self->{text} .= $line;
	}
	1;
}


sub fixed {
	shift->write ($_[0]);
}

sub fixed_start {
}

sub fixed_end {
}

sub bold {
	shift->write ($_[0]);
}

sub bold_start {
}

sub bold_end {
}


sub color {
	shift->write ($_[0]);
}

sub color_start {
}

sub color_end {
}


sub pre {
	shift->write ($_[0]);
}

sub pre_start {
}

sub pre_end {
}


sub p {
	shift->write ("\n\n");
}

sub br {
	shift->write ("\n");
}

sub hr {
	shift->write (("-" x 60) );
}

sub image {
	shift->write ("[IMAGE]");
}

1;
