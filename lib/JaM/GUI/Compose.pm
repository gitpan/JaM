# $Id: Compose.pm,v 1.16 2001/08/19 09:56:45 joern Exp $

package JaM::GUI::Compose;

@ISA = qw ( JaM::GUI::Component );

use strict;
use JaM::Drop;
use JaM::GUI::Component;
use JaM::GUI::MailAsText;
use Data::Dumper;
use MIME::Entity;
use MIME::Types;
use Net::SMTP;
use File::Basename;
use POSIX;
use Carp;

sub gtk_win		{ my $s = shift; $s->{gtk_win}
		          = shift if @_; $s->{gtk_win}			}
sub gtk_toolbar		{ my $s = shift; $s->{gtk_toolbar}
		          = shift if @_; $s->{gtk_toolbar}		}
sub gtk_notebook	{ my $s = shift; $s->{gtk_notebook}
		          = shift if @_; $s->{gtk_notebook}		}
sub gtk_subject		{ my $s = shift; $s->{gtk_subject}
		          = shift if @_; $s->{gtk_subject}		}
sub gtk_text		{ my $s = shift; $s->{gtk_text}
		          = shift if @_; $s->{gtk_text}			}
sub gtk_to_vbox		{ my $s = shift; $s->{gtk_to_vbox}
		          = shift if @_; $s->{gtk_to_vbox}		}
sub gtk_to_entries	{ my $s = shift; $s->{gtk_to_entries}
		          = shift if @_; $s->{gtk_to_entries}		}
sub gtk_to_options	{ my $s = shift; $s->{gtk_to_options}
		          = shift if @_; $s->{gtk_to_options}		}
sub gtk_to_sw		{ my $s = shift; $s->{gtk_to_sw}
		          = shift if @_; $s->{gtk_to_sw}		}
sub gtk_attachment_list	{ my $s = shift; $s->{gtk_attachment_list}
		          = shift if @_; $s->{gtk_attachment_list}	}
sub to_header_choices	{ my $s = shift; $s->{to_header_choices}
		          = shift if @_; $s->{to_header_choices}	}
sub attachments		{ my $s = shift; $s->{attachments}
		          = shift if @_; $s->{attachments}		}
sub additional_headers	{ my $s = shift; $s->{additional_headers}
		          = shift if @_; $s->{additional_headers}	}
sub no_signature	{ my $s = shift; $s->{no_signature}
		          = shift if @_; $s->{no_signature}		}
sub save_as_template	{ my $s = shift; $s->{save_as_template}
		          = shift if @_; $s->{save_as_template}		}
sub save_as_draft	{ my $s = shift; $s->{save_as_draft}
		          = shift if @_; $s->{save_as_draft}		}
			  
sub delete_mail_after_send  { my $s = shift; $s->{delete_mail_after_send}
		              = shift if @_; $s->{delete_mail_after_send}  }

sub add_header {
	my $self = shift;
	my ($name, $value) = @_;
	
	push @{$self->{additional_headers}},
		{ name => $name, value => $value };
	
	1;
}

sub build {
	my $self = shift;

	my $win = Gtk::Window->new;
	my $vpane = new Gtk::VPaned();
	$win->add ($vpane);
	my $vbox_head = Gtk::VBox->new (0, 5);
	$vbox_head->show;
	my $vbox_body = Gtk::VBox->new (0, 5);
	$vbox_body->show;
	$vpane->add1 ($vbox_head);
	$vpane->add2 ($vbox_body);
	$vpane->set_handle_size( 10 );
	$vpane->set_gutter_size( 15 );
	$vpane->show();
	
	my $toolbar  = $self->create_toolbar;
	my $notebook = $self->create_notebook;
	my $subject  = $self->create_subject;
	my $body     = $self->create_body;

	$vbox_head->pack_start ($toolbar,  0, 1, 0);
	$vbox_head->pack_start ($notebook, 1, 1, 0);
	$vbox_body->pack_start ($subject,  0, 1, 0);
	$vbox_body->pack_start ($body,     1, 1, 0);
	
	$win->set_position ("center");
	$win->set_title ("Compose a message");
	$win->border_width(3);
	$win->set_default_size (600, 700);
	$win->realize;
	$win->signal_connect ("delete-event", sub { $self->close_window } );

	$self->gtk_to_entries->[0]->grab_focus;
	$self->gtk_win($win);
	$self->attachments([]);
	$self->additional_headers([]);
	$win->show;

	1;
}

sub create_toolbar {
	my $self = shift; $self->trace_in;
	
	my $toolbar = Gtk::Toolbar->new ( 'horizontal', 'text' );
	$toolbar->set_space_size( 3 );
	$toolbar->set_space_style( 'empty' );
	$toolbar->set_button_relief( 'none' ); 
	$toolbar->border_width( 0 );

	my $label = $self->save_as_template ?
		'Save As Template' : 'Send Message';
	my $tooltip = $self->save_as_template ?
		'Save as template' : 'Send message';

	my $send_button = $toolbar->append_item (
		$label, $tooltip, undef, undef
	);

	$send_button->signal_connect ("clicked", sub { $self->cb_send_button (@_) } );

	$toolbar->show();
	$self->gtk_toolbar ($toolbar);

	return $toolbar;
}

sub create_notebook {
	my $self = shift; $self->trace_in;
	
	my $to_sw = new Gtk::ScrolledWindow(undef, undef);
	$to_sw->set_policy('never', 'automatic');
	$to_sw->show;

	my $to_vbox = Gtk::VBox->new (0,0);
	$to_vbox->show;
	$to_sw->add_with_viewport ($to_vbox);
	$self->gtk_to_vbox ( $to_vbox);
	
	$self->gtk_to_entries ([]);
	$self->gtk_to_options ([]);
	$self->to_header_choices ([]);
	$self->add_recipient_widget;

	my $notebook = Gtk::Notebook->new;
	$notebook->set_tab_pos ('left');
	$notebook->set_usize (undef, 100);

	my $to_label = Gtk::Label->new("To");
	$to_label->show;
	$notebook->append_page ($to_sw, $to_label);
	
	my $attach = $self->create_attachments;
	
	my $attach_label = Gtk::Label->new ("Attach");
	$attach->show;
	$notebook->append_page ($attach, $attach_label);
	
	$notebook->show;
	$self->gtk_notebook($notebook);
	$self->gtk_to_sw ($to_sw);
	
	return $notebook;
}

sub create_attachments {
	my $self = shift;
	
	my $vbox = Gtk::VBox->new (0,0);
	$vbox->show;
	
	my $sw = Gtk::ScrolledWindow->new;
	$sw->set_policy('never', 'automatic');
	$sw->show;
	$vbox->pack_start ($sw, 1, 1, 0);

	my $list = Gtk::List->new;
	$list->show;
	$sw->add_with_viewport($list);
	$list->selection_mode ("browse");
	
	my $hbox = Gtk::HBox->new (0, 5);
	$hbox->show;
	$vbox->pack_start($hbox, 0, 1, 0);
	
	my $add_button = Gtk::Button->new (" Add Attachment ");
	$add_button->show;
	$hbox->pack_start($add_button, 0, 1, 0);
	$add_button->signal_connect("clicked", sub { $self->cb_add_button (@_) });

	my $del_button = Gtk::Button->new (" Delete Attachment ");
	$del_button->show;
	$hbox->pack_start($del_button, 0, 1, 0);
	$del_button->signal_connect("clicked", sub { $self->cb_del_button (@_) });

	$self->gtk_attachment_list ( $list );
	
	return $vbox;
}

sub add_recipient_widget {
	my $self = shift;
	
	my $to_hbox = Gtk::HBox->new (0,0);
	$to_hbox->show;
	my $to_options_menu = Gtk::Menu->new;
	my $i = @{$self->to_header_choices};
	foreach my $header ( "To", "CC", "BCC", "Reply-To" ) {
		my $item = Gtk::MenuItem->new ($header);
		$item->show;
		$item->signal_connect ("activate", \&cb_set_header_choice, $self, $i, $header );
		$to_options_menu->append ($item);
	}
	my $to_options = Gtk::OptionMenu->new;
	$to_options->set_menu($to_options_menu);
	$to_options->show;
	$to_hbox->pack_start($to_options, 0, 1, 0);
	my $to_entry = Gtk::Entry->new;
	my $nr = scalar(@{$self->gtk_to_entries});
	$to_entry->signal_connect_after("key_press_event", sub { $self->cb_to_entry_key_press (@_, $nr) });
	$to_entry->show;
	$to_hbox->pack_start($to_entry, 1, 1, 0);

	$self->gtk_to_vbox->pack_start($to_hbox, 0, 1, 0);
	
	push @{$self->gtk_to_entries}, $to_entry;
	push @{$self->gtk_to_options}, $to_options;

	push @{$self->to_header_choices}, "To";
	
	return $to_entry;
}

sub cb_set_header_choice {
	my ($widget, $self, $i, $header) = @_;
	$self->to_header_choices->[$i] = $header;
}

sub cb_to_entry_key_press {
	my $self = shift;
	my ($widget, $event, $nr) = @_;
	
	if ( $event->{keyval} == 65289 or $event->{keyval} == 65293 ) {
		my $text = $widget->get_text;
		if ( $text !~ /\@/ and $self->config('default_recipient_domain') ) {
			$text .= '@'.$self->config('default_recipient_domain');
			$widget->set_text($text);
		}
	}
	
	if ( $event->{keyval} == 65289 ) {
		$self->gtk_subject->grab_focus;

	} elsif ( $event->{keyval} == 65293 ) {
		if ( $nr+1 >= @{$self->gtk_to_entries} ) {
			$self->add_recipient_widget->grab_focus;
			my $adj = $self->gtk_to_sw->get_vadjustment;
			$adj->set_value($adj->upper);
		} else {
			$self->gtk_to_entries->[$nr+1]->grab_focus;
		}
	}
	
	1;
}

sub create_subject {
	my $self = shift; $self->trace_in;
	
	my $hbox = Gtk::HBox->new (0, 10);
	$hbox->show;
	
	my $label = Gtk::Label->new ("Subject:");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);
	
	my $subject = Gtk::Entry->new;
	my $style = $subject->style->copy;
	$style->font ($self->config('font_mail_compose'));
	$subject->set_style ($style);
	$subject->signal_connect_after("key_press_event", sub { $self->cb_subject_key_press (@_) });
	$subject->show;
	$hbox->pack_start ($subject, 1, 1, 0);

	$self->gtk_subject($subject);

	return $hbox;
}

sub cb_subject_key_press {
	my $self = shift;
	my ($widget, $event) = @_;
	
	if ( $event->{keyval} == 65293 or $event->{keyval} == 65289 ) {
		$self->gtk_text->grab_focus();
	}
	
	return 1;
}

sub create_body {
	my $self = shift; $self->trace_in;
	
	# Create a table
	my $table = new Gtk::Table( 2, 2, 0 );
	$table->set_row_spacing( 0, 2 );
	$table->set_col_spacing( 0, 2 );
	$table->show();

	# Create the Text widget
	my $text = new Gtk::Text( undef, undef );
	$text->set_editable( 1 );
	$text->set_word_wrap ( 1 );
	$table->attach( $text, 0, 1, 0, 1,
        	       [ 'expand', 'shrink', 'fill' ],
        	       [ 'expand', 'shrink', 'fill' ],
        	       0, 0 );
	my $style = $text->style->copy;
	$style->font ($self->config('font_mail_compose'));
	$text->set_style ($style);
	$text->signal_connect ("key_press_event", sub { $self->cb_text_key_press (@_) });
	$text->show();

	# Add a vertical scrollbar to the GtkText widget
	my $vscrollbar = new Gtk::VScrollbar( $text->vadj );
	$table->attach( $vscrollbar, 1, 2, 0, 1, 'fill',
        	       [ 'expand', 'shrink', 'fill' ], 0, 0 );
	$vscrollbar->show();

	$self->gtk_text ($text);

	$self->add_signature if not $self->no_signature;
	$text->set_point (0);

	return $table;
}

sub cb_text_key_press {
	my $self = shift;
	my ($widget, $event) = @_;

	my $keyval = $event->{keyval};
	$self->debug ("keyval=$keyval");

	if ( $keyval == 65293 ) {
		# enter key should delete actual selection
		$widget->delete_selection;

	} elsif ( $keyval == 113 ) {
		# Ctrl Q removes quoted stuff
		$widget->freeze;
		my $index = $widget->get_point;
		my $len   = $widget->get_length;
		my $text  = $widget->get_chars (0, $len);
		$text =~ s/(.{$index})//s;
		my $line;
		my $cnt;
		while ( $text =~ /^(.*)$/mg ) {
			$line = $1;
			last if $line !~ m/^\s*>/ and $line !~ /^\s*$/;
			$cnt += length($line)+1;
		}
		$widget->forward_delete($cnt);
		$widget->insert (undef, undef, undef, "\n");
		$widget->thaw;
	}
	
	return;
}

sub add_signature {
	my $self = shift;
	my $file = "$ENV{HOME}/.signature";
	return if not -r $file;
	
	my $text = $self->gtk_text;
	$text->insert (undef, undef, undef, "\n-- \n");

	open (IN, $file) or warn ("can't read signature file $file");
	while (<IN>) {
		$text->insert ( undef, undef, undef, $_ );
	}
	close IN;
	
	1;
}

sub cb_send_button {
	my $self = shift;
	my %par = @_;

	my $to_entries = $self->gtk_to_entries;
	my $to_headers = $self->to_header_choices;
	
	my (%header, $field, $value, $i);
	my @to;
	foreach my $entry ( @{$to_entries} ) {
		$value = $entry->get_text;
		if ( $value ) {
			push @to, $value;
			$field = $to_headers->[$i];
			if ( $field ne 'BCC' ) {
				push @{$header{$field}}, $value;
			}
		}
		++$i;
	}
	
	my $account = JaM::Account->load_default ( dbh => $self->dbh )
		or return;

	my $from = $account->from_name." <".$account->from_adress.">";
	my $subject = $self->gtk_subject->get_text;
	
	my $gtk_text = $self->gtk_text; 
	my $len = $gtk_text->get_length;
	
	my $text = $gtk_text->get_chars (0, $len);
	$self->wrap_mail_text ( text_sref => \$text, length => 72 );
	
	my $x_mailer =
		$self->config('x_mailer').", Version ".
		$JaM::VERSION;
	
	foreach my $add_head ( @{$self->additional_headers} ) {
		$header{"$add_head->{name}:"} = $add_head->{value};
	}
	
	my $mail = MIME::Entity->build (
		%header,
		From => $from,
		Subject => $subject,
		Date => $self->get_rfc822_date,
		Data => [ $text ],
		Charset => 'iso-8859-1',
		'X-Mailer' => $x_mailer,
	);

	$self->debug($mail->as_string);

	$self->add_attachments_to_mail (
		mail => $mail,
	);

	if ( not $self->save_as_draft and not $self->save_as_template ) {
		my $smtp;
		eval {
			$smtp = Net::SMTP->new(
				$account->smtp_server,
				Hello   => $self->config('smtp_hello'),
				Timeout => 60,
				Debug   => 0,
			);
			die "Helo" if not $smtp;
			die "From" if not $smtp->mail($from);
			die "To"       if not $smtp->to(@to);
			die "Data"     if not $smtp->data();
			$self->debug("now mail->as_string");
			die "Body"     if not $smtp->datasend($mail->as_string);
			$self->debug("finished mail->as_string");
			die "Dataend"  if not $smtp->dataend();
		};
		if ( $@ ) {
			warn "smtp error: $@";
			return 1;
		}
	}

	my $dropper = JaM::Drop->new (
		dbh  => $self->dbh,
		type => 'output',
	);

	my ($mail_id, $folder_id);
	
	if ( not $self->save_as_draft and not $self->save_as_template  ) {
		($mail_id, $folder_id) = $dropper->drop_mail (
			entity => $mail,
			status => 'R',
		);

	} else {
		$folder_id = $self->config('drafts_folder_id')
			if $self->save_as_draft;

		$folder_id = $self->config('templates_folder_id')
			if $self->save_as_template;

		($mail_id) = $dropper->drop_mail (
			entity => $mail,
			status => ($self->save_as_draft ? 'N' : 'R'),
			folder_id => $folder_id
		);
	}

	my $subjects = $self->comp('subjects');
	my $folders  = $self->comp('folders');
	my $selected_folder_object = $folders->selected_folder_object;

	$subjects->prepend_new_mail ( mail_id => $mail_id )
		if $selected_folder_object and
		   $folder_id == $selected_folder_object->id;

	$folders->update_folder_item (
		folder_object => JaM::Folder->by_id($folder_id)
	);

	$self->close;
	
	my $delete_mail;
	if ( $delete_mail = $self->delete_mail_after_send ) {
		my $subjects = $self->comp('subjects');
		my $delete_mail_id = $delete_mail->mail_id;

		# is this mail in the currently selected folder?
		# (then we need to update the GUI)

		my $folder_id = $delete_mail->folder_id;

		if ( $folder_id == $subjects->folder_object->folder_id ) {
		     	# find row in subjects
			my $row = 0;
			foreach my $mail_id ( @{$subjects->mail_ids} ) {
				last if $mail_id == $delete_mail_id;
				++$row;
			}

			$subjects->remove_rows (
				rows => [ $row ],
			);
		}
		
		$delete_mail->delete;

		$self->comp('folders')->update_folder_item (
			folder_object => JaM::Folder->by_id($folder_id)
		);
		
	}
	
	return 1;
}

sub get_rfc822_date {
	my $self = shift;

	my ($oldlocale, $date);
	my $now = time();

	# save the old locale
	$oldlocale = POSIX::setlocale (LC_TIME);

	# set the locale to RFC822's
	POSIX::setlocale (LC_TIME, "en");
	
	# generate the local time string
 	$date = POSIX::strftime ("%a, %e %b %Y %T %Z", localtime($now));
	
	# revert the locale
	POSIX::setlocale (LC_TIME, $oldlocale);

	return $date;
}

sub close {
	my $self = shift;
	$self->gtk_win->destroy;
}

sub insert_reply_message {
	my $self = shift;
	my %par = @_;
	my ($mail, $reply_all) = @par{'mail','reply_all'};

	my $mail_comp = $self->comp('mail');
	my $mail_as_text = JaM::GUI::MailAsText->new;

	my $from = $mail->head_get_decoded('from');
	$from =~ s/<.*?>//;
	$from =~ s/\s+/ /g;
	$from =~ s/\s$//;
	if ( $from eq "" ) {
		$from = $mail->head_get_decoded('from');
		$from =~ s/<//;
		$from =~ s/>//;
	}

	$mail_as_text->begin;
	$mail_as_text->write ("$from wrote:\n\n");
	$mail_as_text->write ("> ");
	$mail_as_text->quote(1);

	if ( $mail->body ) {
		$mail_comp->put_mail_text (
			widget => $mail_as_text,
			data => $mail->body->as_string
		);
	}
	$mail_comp->print_child_entities (
		first_time => 1,
		widget => $mail_as_text,
		entity => $mail
	);
	
	my $text = $self->gtk_text;
	$text->insert (undef, undef, undef, $mail_as_text->text);

	my $subject = $mail->joined_head('subject');
	$subject = "Re: $subject" if $subject !~ /^(Re|Aw):/i;
	$self->gtk_subject->set_text ($subject);
	
	my @to_header;
	@to_header = ("from") if not $mail->head_get("reply-to") or $reply_all;
	push @to_header, "reply-to" if  $mail->head_get("reply-to");
	if ( $reply_all ) {
		push @to_header, qw ( to cc );
	}
	
	my $gtk_to_entries    = $self->gtk_to_entries;
	my $gtk_to_options    = $self->gtk_to_options;
	my $to_header_choices = $self->to_header_choices;
	
	my @values;
	my $value;
	my $no_reply_regex =
		"(".
		join ("|", map (quotemeta($_), @{$self->config('no_reply_addresses')})).
		")";

	my %to;
	foreach my $field ( @to_header ) {
		@values = $mail->head_get ($field);
		foreach $value ( @values ) {
			$value = $mail->word_decode ($value);
			$value =~ s/\s+$//;
			my @addresses = Mail::Address->parse ($value);
			foreach my $adr ( @addresses ) {
				$value = $adr->address;
				next if $value =~ /$no_reply_regex/;
				next if $to{$value};
				$gtk_to_entries->[@{$gtk_to_entries}-1]->set_text ($value);
				$gtk_to_options->[@{$gtk_to_entries}-1]->set_history(
					$field eq 'from' or $field eq 'reply-to' ? 0 : 1
				);
				$to_header_choices->[@{$gtk_to_entries}-1] =
					$field eq 'from' or $field eq 'reply-to' ? 'To' : 'CC';
				$self->add_recipient_widget;
				$to{$value} = 1;
			}
		}
	}

	my $msgid;
	if ( $msgid = $mail->head_get('message-id') ) {
		$self->add_header (
			"in-reply-to", $msgid
		);
	}

	1;
}

sub cb_add_button {
	my $self = shift; $self->trace_in;
	
	my $dir = $self->session_parameters->{'attachment_source_dir'};
	$dir ||= $self->config ('attachment_source_dir');
	
	$self->show_file_dialog (
		title	 => "Select attachment file...",
		dir 	 => $dir,
		filename => "",
		confirm  => 0,
		cb 	 => sub { $self->add_attachment ( filename => $_[0] ) }
	);
	
}

sub add_attachment {
	my $self = shift;
	my %par = @_;
	my  ($filename, $mail, $copy_attachments) =
	@par{'filename','mail','copy_attachments'};
	
	confess ("no parameter set")
		if not $filename and not $mail and not $copy_attachments;
	
	$self->session_parameters->{'attachment_source_dir'} = dirname $filename
		if $filename;

	my $attachments = $self->attachments;
	my ($name, $item);
	
	if ( $filename ) {
		$name = basename($filename);
		push @{$attachments}, {
			filename => $filename,
			name => $name
		};

		$item = Gtk::ListItem->new ($name);
		$item->show;
		$self->gtk_attachment_list->append_items($item);

	} elsif ( $mail) {
		$name = "[Fwd: ".$mail->subject."]";
		push @{$attachments}, {
			mail => $mail,
			name => $name
		};

		$item = Gtk::ListItem->new ($name);
		$item->show;
		$self->gtk_attachment_list->append_items($item);

	} elsif ( $copy_attachments ) {
		my $first = 1;
		foreach my $part ( @{$copy_attachments->parts} ) {
			if  ( $first ) {
				$first = 0;
				next;
			}
			$name = $part->filename;
			push @{$attachments}, {
				part   => $part,
				name   => $name
			};
			$item = Gtk::ListItem->new ($name);
			$item->show;
			$self->gtk_attachment_list->append_items($item);
		}
	}
	
	1;
}

sub add_attachments_to_mail {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($mail) = @par{'mail'};
	
	my $attachments = $self->attachments;
	
	foreach my $att ( @{$attachments} ) {
		if ( $att->{filename} ) {
			my $filename = $att->{filename};
			my ($mime_type, $encoding) =
				MIME::Types::by_suffix($filename);
			$mail->attach (
				Path => $filename,
				Type => $mime_type,
				Encoding => $encoding
			);
		} elsif ( $att->{part} ) {
			my $filename = $att->{part}->filename;
			my ($mime_type, $encoding) =
				MIME::Types::by_suffix($filename);
			my $part = $mail->attach (
				Data => $att->{part}->body->as_string,
				Type => $mime_type,
				Encoding => $encoding,
				Filename => $filename
			);
			
		} else {
			$mail->attach (
				Data => $att->{mail}->entity->as_string,
				Type => "message/rfc822",
			);
		}
	}
}

sub forwarded_message {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($mail) = @par{'mail'};
	
	my $subject = $mail->subject;
	$subject = "[Fwd: $subject]";
	$self->gtk_subject->set_text ($subject);

	1;
}

sub cb_del_button {
	my $self = shift; $self->trace_in;
	
	my $list = $self->gtk_attachment_list;
	my $item = $list->selection;
	return 1 if not $item;

	my $index = $list->child_position ($item);
	$list->remove_items ($item);

	my $attachments = $self->attachments;
	splice @{$attachments}, $index, 1;
	
	1;
}

sub wrap_mail_text {
	my $self = shift;
	my %par = @_;
	my ($text_sref, $length) = @par{'text_sref','length'};

	my $new_text = "";
	my $line;
	
	my $DEBUG = 0;
	
	LINE: while ( $$text_sref =~ m/^(.*)$/mg ) {
		$DEBUG && print "read a new line\n";
		$line = $1;
		chomp $line;

		$DEBUG && print "line='$line'\n";
		
		if ( $line =~ /^\s*$/ ) {
			# empty line
			$new_text .= "\n";
			next;
		}

		if ( $line =~ /^(\s+|\s*>)/ ) {
			# we dont wrap indented or quoted lines
			# (which distinguishes this from Text::Wrap)
			$new_text .= $line."\n";
			next;
		}
		
		# now wrap new_line
		while ( 1 ) {
			if ( length($line) > $length ) {
				$DEBUG && print "new_line too long\n";
				my ($left, $right) = ( $line =~ m/^(.{0,$length})(.*)/ );
				$DEBUG && print "left='$left'\n";
				$DEBUG && print "right='$right'\n";
				# did we cut a word?
				if ( $left =~ m/[^\s]$/ and $right =~ m/^[^\s]/ ) {
					$DEBUG && print "we cut a word\n";
					$left =~ s/([^\s]+)$//;
					if ( $left eq '' ) {
						$DEBUG && print "line too long\n";
						$new_text .= "$line\n";
						next LINE;
					}
					$DEBUG && print "word start from left: $1\n";
					$line = "$1$right";
					$new_text .= "$left\n";
				} else {
					$DEBUG && print "we NOT cut a word\n";
					$left =~ s/\s+$//;
					$new_text .= "$left\n";
					$right =~ s/^\s+//;
					$line = $right;
				}
			} else {
				$DEBUG && print "add to new_text: '$line'\n";
				$new_text .= "$line\n";
				last;
			}
		}
	}
	
	$$text_sref = $new_text;
	
	1;
}

sub close_window {
	my $self = shift;
	
	$self->confirm_window (
		message => "Do you want to save the unsent message in the Drafts folder?",
		position => 'center',
		yes_label => "Yes",
		no_label => "No",
		yes_callback => sub {
			$self->save_as_draft(1);
			$self->cb_send_button;
			$self->gtk_win->destroy;
		},
		no_callback  => sub {
			$self->gtk_win->destroy;
		},
	);

	1;
}

sub insert_template_message {
	my $self = shift;
	my %par = @_;
	my ($mail) = @par{'mail'};
	
	my %history = ( "To" => 0, "CC" => 1, "Reply-To" => 3);

	my $gtk_to_entries    = $self->gtk_to_entries;
	my $gtk_to_options    = $self->gtk_to_options;
	my $to_header_choices = $self->to_header_choices;

	my $mail_comp = $self->comp('mail');

	my ($value, @values);
	foreach my $field ( "Reply-To", "To", "CC", ) {
		@values = $mail->head_get ($field);
		foreach $value ( @values ) {
			$value = $mail->word_decode ($value);
			$value =~ s/\s+$//;
			my @addresses = Mail::Address->parse ($value);
			foreach my $adr ( @addresses ) {
				$value = $adr->address;
				$gtk_to_entries->[@{$gtk_to_entries}-1]->set_text ($value);
				$gtk_to_options->[@{$gtk_to_entries}-1]->set_history(
					$history{$field}
				);
				$to_header_choices->[@{$gtk_to_entries}-1] = $field;
				$self->add_recipient_widget;
			}
		}
	}

	if ( $mail->body ) {
		my $text = $self->gtk_text;
		$text->insert (undef, undef, undef, $mail->body->as_string);
	} elsif ( $mail->parts ) {
		my $text = $self->gtk_text;
		$text->insert (undef, undef, undef, $mail->parts->[0]->body->as_string);
	}
	
	my $subject = $mail->joined_head('subject');
	$self->gtk_subject->set_text ($subject);
	
	$self->add_attachment (
		copy_attachments => $mail
	);
	
	1;
}

1;
