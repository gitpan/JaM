# $Id: Mail.pm,v 1.14 2001/08/17 20:08:19 joern Exp $

package JaM::GUI::Mail;

@ISA = qw ( JaM::GUI::Component );

use strict;
use FileHandle;
use JaM::GUI::Component;
use JaM::GUI::HTMLSurface;

# get/set gtk object for mail content scrolled window
sub gtk_mail_html	{ my $s = shift; $s->{gtk_mail_html}
		          = shift if @_; $s->{gtk_mail_html}		}

# get/set gtk object for mail content HTMLSurface object
sub gtk_mail_html_object{ my $s = shift; $s->{gtk_mail_html_object}
		          = shift if @_; $s->{gtk_mail_html_object}	}

# get/set gtk object for mail popup menu
sub gtk_popup		{ my $s = shift; $s->{gtk_popup}
		          = shift if @_; $s->{gtk_popup}		}

# get/set actual viewed mail (JaM::Mail object)
sub mail 		{ my $s = shift; $s->{mail}
		          = shift if @_; $s->{mail}			}

# get/set actual flag for viewing all header fields or only common fields
sub show_all_header 	{ my $s = shift; $s->{show_all_header}
		          = shift if @_; $s->{show_all_header}		}


# build mail viewer widget
sub build {
	my $self = shift;

	# Create a table to hold the text widget and scrollbars
	my $sw = new Gtk::ScrolledWindow(undef, undef);
	$sw->set_policy('automatic', 'automatic');

	my $html = JaM::GUI::HTMLSurface->new (
		image_dir => "/tmp",
		button3_callback => sub { $self->popup_menu(@_) }
	);
	my $widget = $html->widget;
	$sw->show;
	$sw->add($widget);

	# Add a handler to put a message in the html widget when it is realized
	$self->gtk_mail_html ($widget);
	$self->gtk_mail_html_object ($html);

	$self->widget ($sw);

	# build popup menu for right click
	my $item;
	my $popup = $self->gtk_popup (Gtk::Menu->new);

	$item = Gtk::MenuItem->new ("Show only common header fields");
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_show_all_header(0) } );
	$item->show;

	$item = Gtk::MenuItem->new ("Show complete header");
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_show_all_header(1) } );
	$item->show;
	
	return $self;
}	

sub show {
	my $self = shift;
	my %par = @_;
	my ($mail_id) = @par{'mail_id'};

	$self->clear;

	my $html = $self->gtk_mail_html_object;
	$html->widget->freeze;
	$html->begin;
	
	if ( not $mail_id ) {
		$html->end;
		$html->widget->thaw;
		$self->mail(undef);
		return;
	}

	my $mail = JaM::Mail->load (
		dbh => $self->dbh,
		mail_id  => $mail_id,
	);
	
	$self->mail ($mail);

	# first print the header
	$self->print_entity_head (
		entity => $mail,
		widget => $html,
	);

	# print primary body, if given
	if ( $mail->body ) {
		$self->put_mail_text (
			widget => $html,
			data => $mail->body->as_string
		);
	}

	# print child entitities
	$self->print_child_entities (
		first_time => 1,
		widget => $html,
		entity => $mail,
	);

	$html->end;
	$html->widget->thaw;

	$mail->status ( 'R' );

	1;
}

sub clear {
	my $self = shift;
	my $html = $self->gtk_mail_html_object;
	$html->begin;
	$html->end;
	$self->mail(undef);
	$self->comp('subjects')->selected_mail_id(undef);
	1;
}

sub move_to_folder {
	my $self = shift;
	my %par = @_;
	my ($mail, $mail_ids, $folder_object) = @par{'mail','mail_ids','folder_object'};
	
	if ( not $mail_ids and not $mail ) {
		$mail ||= $self->mail;
	}
	return if not $mail and not $mail_ids;
	
	my $folder_id = $folder_object->id;

	if ( $mail ) {
		$mail->move_to_folder ( folder_id => $folder_id );

	} else {
		foreach my $mail_id ( @{$mail_ids} ) {
			$mail =  JaM::Mail->load (
				mail_id => $mail_id,
				dbh     => $self->dbh
			);
			$mail->move_to_folder (
				folder_id => $folder_id
			);
		}
	}
	
	$self->comp('folders')->update_folder_item (
		folder_object => $folder_object
	);


	1;
}

sub print_entity_head {
	my $self = shift;
	my %par = @_;
	my  ($entity, $widget) =
	@par{'entity','widget'};

	$widget->write ('<table border="0" cellpadding="0" cellspacing="2">');

	my $name = $entity->entity_id;
	$widget->image_pool->{$name}->{entity} = $entity->entity;
	my $subject = $self->quote($entity->joined_head('subject'));
	$subject = "<a href=\"mail://".$entity->entity_id."\">$subject</a>";
	
	$self->debug("subject: $subject");
	
	$widget->write (
		'<tr><td align="right"><b>Subject:</b></td><td>&nbsp;</td><td><b>',
		$subject,
		'</b></td></tr>',
	);
	
	$widget->write (
		'<tr><td align="right"><b>Date:</b></td><td>&nbsp;</td><td>',
		$self->quote($self->format_date ( date => $entity->date )),
		'</td></tr>'
	);

	$widget->write (
		'<tr><td align="right"><b>From:</b></td><td>&nbsp;</td><td>',
		$self->quote($entity->joined_head('from')),
		'</td></tr>'
	);

	if ( $entity->joined_head('reply-to') ) {
		$widget->write (
			'<tr><td align="right"><b>Reply-To:</b></td><td>&nbsp;</td><td>',
			$self->quote($entity->joined_head('reply-to')),
			'</td></tr>'
		);
	}

	if ( $entity->joined_head('to') ) {
		$widget->write (
			'<tr><td align="right"><b>To:</b></td><td>&nbsp;</td><td>',
			$self->quote($entity->joined_head('to')),
			'</td></tr>'
		);
	}

	if ( $entity->joined_head('cc') ) {
		$widget->write (
			'<tr><td align="right"><b>CC:</b></td><td>&nbsp;</td><td>',
			$self->quote($entity->joined_head('cc')),
			'</td></tr>'
		);
	}

	$widget->write ('</table>');

	if ( $self->show_all_header ) {
		$self->print_entity_full_head (
			entity => $entity,
			widget => $widget
		);
	} else {
		$widget->p;
	}
	
	1;
}

sub print_entity_full_head {
	my $self = shift;
	my %par = @_;
	my  ($entity, $widget) =
	@par{'entity','widget'};

	$widget->pre ($self->quote($entity->head->as_string));

	$widget->p;
	
	1;
}

sub quote {
	my $par = $_[1];
	$par =~ s/</&lt;/g;
	return $par;
}

sub print_child_entities {
	my $self = shift;
	my %par = @_;
	my  ($entity, $widget, $first_time) =
	@par{'entity','widget','first_time'};
	
	my $childs = $entity->parts;

	my $parent_content_type = $entity->content_type;

	my $alternative_part_content_type = "text/plain";
	if ( $parent_content_type eq 'multipart/alternative' ) {
		# determine which part we wanna see
		foreach my $child ( @{$childs} ) {
			# if we have multipart/mixed, we prefer it
			$alternative_part_content_type = "multipart/mixed"
				if  $child->content_type eq "multipart/mixed";
		}
	}

	foreach my $child ( @{$childs} ) {

		my ($print_header, $print_body);
		my $child_content_type  = $child->content_type;
		
		if ( $child_content_type =~ /^multipart/ ) {
			$self->print_delimiter ( widget => $widget )
				if not $first_time;
			$first_time = 0;

			$self->print_entity_head (
				entity => $child,
				widget => $widget,
			) if $child->subject;

			$first_time = $self->print_child_entities (
				entity => $child,
				widget => $widget,
				first_time => 1,
			);
			next;
		}
		
		$first_time = $self->print_child_entities (
			entity => $child,
			widget => $widget,
			first_time => $first_time
		);

		# discard wrong multipart/alternative part
		next if $parent_content_type eq 'multipart/alternative' and
		        $child_content_type ne $alternative_part_content_type;

		if ( $child->body ) {
			$self->print_delimiter ( widget => $widget )
				if not $first_time;

			$self->debug ("child content type: $child_content_type");

			if ( $parent_content_type eq 'message/rfc822' ) {
				$self->print_entity_head (
					entity => $child,
					widget => $widget,
				);
			}
			
			if ( $child_content_type eq "text/html" ) {
				$self->put_inline_download_link (
					entity => $child,
					widget => $widget,
				);
				$self->put_mail_text (
					widget => $widget,
					data => "\nWARNING: FILTERED HTML MAIL!!!\n\n".
					        $self->html_filter($child->body->as_string)
				);

			} elsif ( $child_content_type =~ /^(message|text)/ ) {
				my $data = $child->body->as_string;
				if ( $child_content_type =~ /^text/ and
				     not $first_time and $data ne ''
				     ) {
					$self->put_inline_download_link (
						entity => $child,
						widget => $widget,
					);
				}
				$self->put_mail_text (
					widget => $widget,
					data => $data
				);

			} elsif ( $child_content_type =~ /^image/) {
				$self->put_image_part (
					widget => $widget,
					entity => $child,
				);

			} else {
				$self->put_image_part (
					widget => $widget,
					entity => $child,
					no_display => 1,
				);
			}

			$first_time = 0;

		} else {
			# print "no body\n";
		}
	}
	
	return $first_time;
}

sub html_filter {
	my $self = shift;
	my ($html) = @_;

	$html =~ s/<\!--.*?-->//sg;
	$html =~ s/<.*?>//sg;
	$html =~ s/&nbsp;/ /sg;
	$html =~ s/&quot;/"/sg;
	$html =~ s/\n+/\n/sg;

	return $html;
}

sub print_delimiter {
	my $self = shift;
	my %par = @_;
	my ($widget) = @par{'widget'};
	$widget->p;
	$widget->hr;
	$widget->p;
}

sub put_mail_text {
	my $self = shift;
	my %par = @_;
	my ($widget, $data, $no_table) =  @par{'widget', 'data', 'no_table'};
	
	my $quoted_color = $self->config('quoted_color');
	
	$data =~ s/</&lt;/g;
	$data =~ s!(http://[^\s]+)!<a href="$1">$1</a>!g;
	$data =~ s!^(\s*)(>.*)$!$1<font face="Courier" color="$quoted_color">$2</font>!mg;

	$widget->write ('<table border="0" cellpadding="0" cellspacing="2"><tr><td>')
		if not $no_table;
	$widget->pre ($data);
	$widget->write ("</td></tr></table>")
		if not $no_table;
}

sub put_inline_download_link {
	my $self = shift;
	my %par = @_;
	my  ($widget, $entity) =
	@par{'widget','entity'};
	
	my $name = $entity->entity_id;
	$widget->image_pool->{$name}->{body} = $entity->body;
	$widget->image_pool->{$name}->{head} = $entity->head;
	
	$widget->write (
		"<a href=\"pool://".$entity->entity_id."\">".
		"<b>[ Save attachment as... ]</b>".
		"</a><p>"
	);
	
	1;
}

sub put_image_part {
	my $self = shift;
	my %par = @_;
	my  ($widget, $entity, $no_display) =
	@par{'widget','entity','no_display'};
	
	my $name = $entity->entity_id;
	$widget->image_pool->{$name}->{body} = $entity->body;
	$widget->image_pool->{$name}->{head} = $entity->head;
	
	$widget->write ('<table border="0" cellpadding="0" cellspacing="2"><tr><td>');
	if ( $no_display ) {
		$widget->write (
			"<a href=\"pool://".$entity->entity_id."\">".
			"<b>This attachment is not presentable</b>".
			"</a>"
		);
	} else {
		$widget->image ( pool => $name );
	}

	$widget->write ("</td></tr>");
	$widget->write ("<tr><td>");

	$widget->bold ("Mime-Type: ");
	$widget->write ($entity->content_type);
	$widget->br;
	
	$widget->bold ("Filename: ");
	$widget->write ($entity->filename);
	$widget->br;

	$widget->bold ("Size: ");
	$widget->write (int($entity->content_length/1024)." KB");
	$widget->br;

	$widget->write ("</td></tr></table>");
}

sub popup_menu {
	my $self = shift;
	my ($event) = @_;

	$self->gtk_popup->popup (undef, undef, $event->{button}, 0);
}

sub cb_show_all_header {
	my $self = shift;
	my ($flag) = @_;
	$self->show_all_header($flag);
	return if not $self->mail;
	$self->show (mail_id => $self->mail->mail_id);
	1;
}

1;
