# $Id: Folders.pm,v 1.15 2001/08/14 21:12:50 joern Exp $

package JaM::GUI::Folders;

@ISA = qw ( JaM::GUI::Component );

use strict;
use JaM::GUI::Component;
use JaM::Folder;

my $DEBUG = 0;

my @closed_xpm = ( "16 16 6 1",
                  "       c None s None",
                  ".      c black",
                  "X      c #a0a0a0",
                  "o      c yellow",
                  "O      c #808080",
                  "#      c white",
                  "                ",
                  "       ..       ",
                  "     ..XX.      ",
                  "   ..XXXXX.     ",
                  " ..XXXXXXXX.    ",
                  ".ooXXXXXXXXX.   ",
                  "..ooXXXXXXXXX.  ",
                  ".X.ooXXXXXXXXX. ",
                  ".XX.ooXXXXXX..  ",
                  " .XX.ooXXX..#O  ",
                  "  .XX.oo..##OO. ",
                  "   .XX..##OO..  ",
                  "    .X.#OO..    ",
                  "     ..O..      ",
                  "      ..        ",
                  "                ");
my @open_xpm = ( "16 16 4 1",
                "       c None s None",
                ".      c black",
                "X      c #808080",
                "o      c white",
                "                ",
                "  ..            ",
                " .Xo.    ...    ",
                " .Xoo. ..oo.    ",
                " .Xooo.Xooo...  ",
                " .Xooo.oooo.X.  ",
                " .Xooo.Xooo.X.  ",
                " .Xooo.oooo.X.  ",
                " .Xooo.Xooo.X.  ",
                " .Xooo.oooo.X.  ",
                "  .Xoo.Xoo..X.  ",
                "   .Xo.o..ooX.  ",
                "    .X..XXXXX.  ",
                "    ..X.......  ",
                "     ..         ",
                "                ");
my @leaf_xpm = ( "16 16 4 1",
                "       c None s None",
                ".      c black",
                "X      c white",
                "o      c #808080",
                "                ",
                "   .......      ",
                "   .XXXXX..     ",
                "   .XoooX.X.    ",
                "   .XXXXX....   ",
                "   .XooooXoo.o  ",
                "   .XXXXXXXX.o  ",
                "   .XooooooX.o  ",
                "   .XXXXXXXX.o  ",
                "   .XooooooX.o  ",
                "   .XXXXXXXX.o  ",
                "   .XooooooX.o  ",
                "   .XXXXXXXX.o  ",
                "   ..........o  ",
                "    oooooooooo  ",
                "                ");

@leaf_xpm = @open_xpm = @closed_xpm;

my ($closed_pix, $closed_mask);
my ($opened_pix, $opened_mask);
my ($leaf_pix,   $leaf_mask);

# get/set selected Folder
sub selected_folder_object	{ my $s = shift; $s->{selected_folder_object	}
		          	  = shift if @_; $s->{selected_folder_object}	}

# get/set selected Folder object on which a Popup is requested
sub popup_folder_object	{ my $s = shift; $s->{popup_folder_object}
		          = shift if @_; $s->{popup_folder_object}		}

# get/set selected row on which a Popup is requested
sub popup_row           { my $s = shift; $s->{popup_row}
		          = shift if @_; $s->{popup_row}			}

# get/set list ref of folder gtk items
sub gtk_folder_items	{ my $s = shift; $s->{gtk_folder_items}
		          = shift if @_; $s->{gtk_folder_items}			}

# get/set gtk object for folder scrollable window
sub gtk_folders		{ my $s = shift; $s->{gtk_folders}
		          = shift if @_; $s->{gtk_folders}			}

# get/set gtk object for folder ctree
sub gtk_folders_tree	{ my $s = shift; $s->{gtk_folders_tree}
		          = shift if @_; $s->{gtk_folders_tree}			}

# get/set gtk style for folder without new mails
sub gtk_read_style	{ my $s = shift; $s->{gtk_read_style}
		          = shift if @_; $s->{gtk_read_style}			}

# get/set gtk style for folder with unread mails
sub gtk_unread_style	{ my $s = shift; $s->{gtk_unread_style}
		          = shift if @_; $s->{gtk_unread_style}			}

# get/set gtk style for folder with unread child folders
sub gtk_unread_child_style { my $s = shift; $s->{gtk_unread_child_style}
		             = shift if @_; $s->{gtk_unread_child_style}			}

# helper method for setting up pixmaps
sub initialize_pixmap {
	my $self = shift; $self->trace_in;
	my @xpm = @_;

	my ($pixmap, $mask);
	my $win   = $self->gtk_win;
	my $style = $win->get_style()->bg( 'normal' );

	return ($pixmap, $mask) = Gtk::Gdk::Pixmap->create_from_xpm_d (
		$win->window, $style, @xpm
	);
}

# build scrolled window for folder ctree
sub build {
	my $self = shift; $self->trace_in;
	
	JaM::Folder->init ( dbh => $self->dbh );
	
	my $folders = new Gtk::ScrolledWindow (undef, undef);
	$folders->set_policy ('automatic', 'automatic');
	$folders->set_usize($self->config('folders_width'), undef);

	$folders->signal_connect("size-allocate",
		sub { $self->config('folders_width', $_[1]->[2]) }
	);

	# Set up Pixmaps
	($closed_pix, $closed_mask) = $self->initialize_pixmap( @closed_xpm );
	($opened_pix, $opened_mask) = $self->initialize_pixmap( @open_xpm );
	($leaf_pix,   $leaf_mask)   = $self->initialize_pixmap( @leaf_xpm );

	my $root_tree = Gtk::CTree->new_with_titles (
		0, 'Name','Unread','Total'
	);

	$root_tree->signal_connect("resize-column",
		sub {
			$self->config('folders_column_'.$_[1], $_[2]);
		}
	);

	$root_tree->set_column_width (0, $self->config('folders_column_0'));
	$root_tree->set_column_width (1, $self->config('folders_column_1'));
	$root_tree->set_column_width (2, $self->config('folders_column_2'));
	$root_tree->set_reorderable(1);
	$root_tree->set_line_style ('dotted');
#	$root_tree->set_user_data ($self);
	$root_tree->signal_connect ('select_row', sub { $self->cb_folder_select(@_) } );
	$root_tree->signal_connect ('tree-expand', sub {
		$self->cb_tree_click ( type => 'expand', tree => $_[0], node => $_[1] ) }
	);
	$root_tree->signal_connect ('tree-collapse', sub {
		$self->cb_tree_click ( type => 'collapse', tree => $_[0], node => $_[1] ) }
	);
	$root_tree->signal_connect ('tree-move', sub {
		$self->cb_tree_move ( @_ ) }
	);

	$root_tree->set_selection_mode( 'browse' );
	$folders->add_with_viewport($root_tree);
	$root_tree->show;

	# build tree
	my $unread_style = $root_tree->style->copy;
	$unread_style->font($self->config('font_folder_unread'));
	my $read_style = $root_tree->style->copy;
	$read_style->font($self->config('font_folder_read'));
	my $unread_child_style = $root_tree->style->copy;
	$unread_child_style->font($self->config('font_folder_unread'));
	$unread_child_style->fg('normal',$self->gdk_color($self->config('folder_unread_child_color')));

	$self->gtk_unread_style ($unread_style);
	$self->gtk_unread_child_style ($unread_child_style);
	$self->gtk_read_style   ($read_style);

	$self->gtk_folder_items ( {} );
	$self->gtk_folders ($folders);
	$self->gtk_folders_tree ($root_tree);

	$self->add_tree (
		tree      => $root_tree,
		parent_id => 0
	);

	$folders->show;
	
	# now build popup Menu
	$root_tree->signal_connect('button_press_event', sub { $self->cb_click_clist(@_) } );
	my $popup = $root_tree->{popup} = Gtk::Menu->new;
	my $item;

	$item = Gtk::MenuItem->new ("Rename Folder...");
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_rename_folder ( @_ ) } );
	$item->show;
	$item = Gtk::MenuItem->new ("Create New Folder...");
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_create_folder ( @_ ) } );
	$item->show;
	$item = Gtk::MenuItem->new ("Delete Folder...");
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_delete_folder ( @_ ) } );
	$item->show;
	
	$item = Gtk::MenuItem->new;
	$popup->append($item);
	$item->show;

	$item = Gtk::MenuItem->new ("Add Input Filter...");
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_add_input_filter ( @_ ) } );
	$item->show;

	$self->widget ($folders);

	$self->update_folder_stati;

	return $self;
}

sub add_tree {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($tree, $parent_id) =
	@par{'tree','parent_id'};

	my $folders_href = JaM::Folder->query ( 
		dbh => $self->dbh,
		where => "parent_id = ?",
		params => [ $parent_id ]
	);

	my $folder_items = $self->gtk_folder_items;
	
	# build sibling hash
	my %sibling;
	for ( keys %{$folders_href} ) {
		$sibling{$folders_href->{$_}->sibling_id} = $folders_href->{$_};
	}

	# we start with the folder, which has no sibling
	my $sibling_id = 99999;
	my $max = scalar(keys(%sibling));

	my ($folder, $sibling_item, $item);
	for (my $i=0; $i < $max; ++$i) {
		$folder = $sibling{$sibling_id};
		$sibling_item = $folder_items->{$sibling_id}
			if $sibling_id != 99999;
		
		$self->insert_folder_item (
			folder_object => $folder,
			sibling_item => $sibling_item,
		);

		$sibling_id = $folder->id;
	}

	1;
}

sub insert_folder_item {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($folder_object, $sibling_item) =
	@par{'folder_object','sibling_item'};
	
	my $folder_items = $self->gtk_folder_items;
	my $tree = $self->gtk_folders_tree;
	my $parent_id = $folder_object->parent_id;
	
	my $item = $folder_items->{$folder_object->id} = $tree->insert_node (
		$folder_items->{$parent_id},
		$sibling_item,
		[ $folder_object->name,
		  $folder_object->mail_sum -
		  $folder_object->mail_read_sum,
		  $folder_object->mail_sum ],
		5,
		$closed_pix, $closed_mask,
		$opened_pix, $opened_mask,
		0, ($folder_object->leaf ? 1 : $folder_object->opened)
	);

	$self->add_tree (
		tree => $tree,
		parent_id => $folder_object->id
	) if not $folder_object->leaf;

	$item->{folder_id} = $folder_object->id;

	$tree->node_set_row_style(
		$item, ($folder_object->mail_read_sum < $folder_object->mail_sum) ?
		       $self->gtk_unread_style : $self->gtk_read_style
	);
	
	return $item;
}

sub cb_click_clist {
	my $self = shift;
	my ($widget, $event) = @_;

	my ( $row, $column ) = $widget->get_selection_info( $event->{x}, $event->{y} );

	$self->popup_folder_object (
		JaM::Folder->by_id($widget->node_nth( $row )->{folder_id})
	);
	$self->popup_row ($widget->node_nth( $row ));

	if ( $event->{button} == 3 and $widget->{'popup'} ) {
		$widget->{'popup'}->popup(undef,undef,$event->{button},1);
	}

	1;
}

sub cb_rename_folder {
	my $self = shift;

	my $folder_object = $self->popup_folder_object;
	my $name = $folder_object->name;

	my $dialog;
	$dialog = $self->folder_dialog (
		title => "Rename Folder",
		label => "Enter new name for folder '$name'",
		value => $name,
		cb => sub {
			my ($text) = @_;
			$self->rename_folder (
				folder_object => $folder_object,
				name => $text->get_text,
			);
			$dialog->destroy;
		}
	);

	1;
}

sub folder_dialog {
	my $self = shift;
	my %par = @_;
	my ($title, $label_text, $value, $cb) = @par{'title','label','value','cb'};

	my $dialog = Gtk::Dialog->new;
	$dialog->border_width(10);
	$dialog->set_position('mouse');
	$dialog->set_modal ( 1 );
	$dialog->set_title ($title);

	my $label = Gtk::Label->new ($label_text);
	$dialog->vbox->pack_start ($label, 1, 1, 0);
	$label->show;
	
	my $text = Gtk::Entry->new ( 40 );
	$dialog->vbox->pack_start ($text, 1, 1, 0);
	$text->set_text ( $value );
	$text->show;
	
	my $ok = new Gtk::Button( "Ok" );
	$dialog->action_area->pack_start( $ok, 1, 1, 0 );
	$ok->signal_connect( "clicked", sub {
		&$cb($text);
		$dialog->destroy;
	} );
	$ok->show();

	my $cancel = new Gtk::Button( "Cancel" );
	$dialog->action_area->pack_start( $cancel, 1, 1, 0 );
	$cancel->signal_connect( "clicked", sub { $dialog->destroy } );
	$cancel->show();
	
	$dialog->show;
	
	return $dialog;
}

sub rename_folder {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($folder_object, $name) = @par{'folder_object','name'};
	
	$self->debug ("folder_id=".$folder_object->id.", name=$name");
	
	return 1 if not $name;
	
	$folder_object->name($name);
	$folder_object->save;
	
	$self->update_folder_item ( folder_object => $folder_object );
	
	1;
}

sub cb_create_folder {
	my $self = shift;

	my $folder_object = $self->popup_folder_object;

	my $dialog;
	$dialog = $self->folder_dialog (
		title => "Create Folder",
		label => "Enter name for the new folder",
		value => "",
		cb => sub {
			my ($text) = @_;
			$self->create_folder (
				parent_folder_object => $folder_object,
				name => $text->get_text,
			);
			$dialog->destroy;
		}
	);

	1;
}

sub cb_tree_click {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($type, $tree, $node) = @par{'type','tree','node'};
	
	my $opened = $type eq 'expand' ? 1 : 0;
	my $folder_object = JaM::Folder->by_id($node->{folder_id});
	
	$folder_object->opened($opened);
	$folder_object->save;

	1;
}

# callback for folder selection
sub cb_folder_select {
	my $self = shift; $self->trace_in;
	my ($ctree, $row) = @_;

	my $node = $ctree->node_nth( $row );
	my $folder_object = JaM::Folder->by_id($node->{folder_id});

	$self->selected_folder_object ( $folder_object );
	$self->comp('subjects')->show ( folder_object => $folder_object );

	my $gui = $self->comp('gui');
	$gui->no_subjects_update (1);
	$gui->update_folder_limit (
		folder_object => $folder_object
	);
	$gui->no_subjects_update (0);
	
	1;
}

# update ctree item for a specific folder from database
sub update_folder_item {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($folder_object, $no_folder_stati) =
	@par{'folder_object','no_folder_stati'};

	$folder_object ||= $self->selected_folder_object;

	$self->debug ("folder_id=".$folder_object->id);

	my $name = $folder_object->name;

	my $item = $self->gtk_folder_items->{$folder_object->id};

	my $widget = $self->gtk_folders_tree;

	my ($text, $spacing, $pixmap, $mask) = $widget->node_get_pixtext( $item, 0 );
	if ( $name ne $text ) {	
		$self->debug ("folder name changed: old=$text new=$name");
		$widget->node_set_pixtext( $item, 0, $name, $spacing, $pixmap, $mask );
	}
	
	my ($mail_sum, $mail_read_sum) = ($folder_object->mail_sum,
					  $folder_object->mail_read_sum);

	$self->debug ("mail_sum=$mail_sum, mail_read_sum=$mail_read_sum");

	$widget->set_text( $item, 1, $mail_sum -
				     $mail_read_sum); 
	$widget->set_text( $item, 2, $mail_sum); 

	$widget->node_set_row_style(
		$item, ($mail_read_sum < $mail_sum) ?
		       $self->gtk_unread_style : $self->gtk_read_style
	);
	
	$self->update_folder_stati
		if not $no_folder_stati;

	1;
}

sub update_folder_stati {
	my $self = shift; $self->trace_in;
	
	$self->debug ("updating folder read/unread stati");
	
	JaM::Folder->recalculate_folder_stati ( dbh => $self->dbh );

	my $folder_items = $self->gtk_folder_items;
	my $folders_tree = $self->gtk_folders_tree;

	my $all_folders = JaM::Folder->all_folders;

	my ($folder_id, $folder, $status, $style);
	while ( ($folder_id, $folder) = each %{$all_folders} ) {
		$status = $folder->status;
		if ( $folder_items->{$folder_id}->{status} ne $status ) {
			$style = $self->gtk_read_style;
			$style = $self->gtk_unread_style if $status eq 'N';
			$style = $self->gtk_unread_child_style if $status eq 'NC';
			$folders_tree->node_set_row_style(
				$folder_items->{$folder_id}, $style
			);
			$folder_items->{$folder_id}->{status} = $status;
		}
	}
	
	1;
}

sub create_folder {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($parent_folder_object, $name) =
	@par{'parent_folder_object','name'};
	
	my $parent_id = $parent_folder_object->id;
	
	$self->debug ("parent_id=$parent_id name=$name");
	
	my $folder_items = $self->gtk_folder_items;
	my $folders_tree = $self->gtk_folders_tree;
	
	$self->dump($folder_items->{$parent_id});

	my $parent_item = $folder_items->{$parent_folder_object->id};
	my $sibling_item;
	my $sibling_folder_object;

	if ( $parent_folder_object->leaf ) {
		$parent_folder_object->leaf (0); 
		$parent_folder_object->save;

	} else {
		my $sibling_id = $parent_folder_object->get_first_child_folder_id;
		$self->debug("sibling_id=$sibling_id");
		if ( $sibling_id ) {
			$sibling_item = $folder_items->{$sibling_id};
			$sibling_folder_object = JaM::Folder->by_id($sibling_id);
		}
	}
	
	my $new_folder = JaM::Folder->create (
		dbh => $self->dbh,
		name => $name,
		parent => $parent_folder_object,
		sibling => $sibling_folder_object
	);

	my $item = $self->insert_folder_item (
		folder_object => $new_folder,
		sibling_item => $sibling_item,
	);

	1;
}

sub cb_tree_move {
	my $self = shift;
	my ($ctree, $moved, $parent, $sibling) = @_;

	return if not $parent;

	my $sibling_object;
	$sibling_object   = JaM::Folder->by_id($sibling->{folder_id}) if $sibling;
	my $moved_object  = JaM::Folder->by_id($moved->{folder_id});
	my $parent_object = JaM::Folder->by_id($parent->{folder_id});

	$self->move_tree (
		moved_object => $moved_object,
		parent_object => $parent_object,
		sibling_object => $sibling_object,
	);
}

sub move_tree {
	my $self = shift;
	my %par = @_;

	my  ($moved_object, $parent_object, $sibling_object) =
	@par{'moved_object','parent_object','sibling_object'};
	
	my $folder_items  = $self->gtk_folder_items;
	
	# is the parent_object a leaf? change that!
	if ( $parent_object->leaf ) {
		$parent_object->leaf(0);
		$parent_object->save;
	}
	
	# if we was the last child, tell our parent,
	# that now it is a leaf
	$self->debug ("sibling_id=".$moved_object->sibling_id." sibling_of_id=",$moved_object->sibling_of_id);
	if ( $moved_object->sibling_id == 99999 and not $moved_object->sibling_of_id ) {
		my $my_parent_object = JaM::Folder->by_id($moved_object->parent_id);
		$my_parent_object->leaf(1);
		$my_parent_object->save;
	}

	# First remove the moved item
	# We have to handle two cases:
	# - it has a sibling
	# - it has no sibling
	if ( $moved_object->sibling_id == 99999 ) {
		# no sibling - now the object we are sibling of
		# will have no sibling anymore
		my $sibling_of_id = $moved_object->sibling_of_id;
		if ( $sibling_of_id ) {
			my $sibling_of = JaM::Folder->by_id($sibling_of_id);
			$sibling_of->sibling_id(99999);
			$sibling_of->save;
		}
	} else {
		# ok, we have a sibling. connect it to the object,
		# we are sibling of
		my $sibling_of_id = $moved_object->sibling_of_id;
		if ( $sibling_of_id ) {
			my $sibling_of = JaM::Folder->by_id($sibling_of_id);
			my $my_sibling = JaM::Folder->by_id($moved_object->sibling_id);
			$sibling_of->sibling_id($my_sibling->id);
			$sibling_of->save;
		}
	}

	# Now place the moved item
	# Again we have two cases:
	# - we'll have a sibling
	# - we'll have no sibling
	if ( $sibling_object ) {
		# ok, we'll have a sibling
		my $sibling_of_id = $sibling_object->sibling_of_id;
		if ( $sibling_of_id ) {
			my $sibling_of = JaM::Folder->by_id($sibling_of_id);
			$sibling_of->sibling_id ($moved_object->id);
			$sibling_of->save;
		}
		$moved_object->sibling_id($sibling_object->id);
	} else {
		# we'll have no sibling
		my $last_folder_id = $parent_object->get_last_child_folder_id;
		$self->debug("last_folder_id=$last_folder_id");
		if ( $last_folder_id ) {
			my $sibling_of = JaM::Folder->by_id($last_folder_id);
			$sibling_of->sibling_id($moved_object->id);
			$sibling_of->save;
		}
		$moved_object->sibling_id(99999);
	}

	# set parent_id
	$moved_object->parent_id ($parent_object->id);
	
	# set new path
	my $path = $parent_object->path;
	$path =~ s!/[^/]+$!/!;
	$path .= $moved_object->name;
	$moved_object->path ($path);

	# save
	$moved_object->save;

	1;
}

sub cb_delete_folder {
	my $self = shift;
	
	my $folder_object = $self->popup_folder_object;
	
	my $trash_id = $self->config('trash_folder_id');
	my $trash_object = JaM::Folder->by_id($trash_id);

	# update database
	$self->move_tree (
		moved_object => $folder_object,
		parent_object => $trash_object,
	);
	
	# update gui: remove item
	my $folder_item = $self->gtk_folder_items->{$folder_object->id};
	$self->gtk_folders_tree->remove ($folder_item);
	
	# update gui: insert into trash
	$self->insert_folder_item (
		folder_object => $folder_object,
		sibling_item => undef,
	);

	1;
}

sub build_menu_of_folders {
	my $self= shift;
	my %par = @_;
	my ($callback) = @par{'callback'};

	my $root_folder = JaM::Folder->by_id(1);

	my $submenu = $self->build_submenu (
		parent => $root_folder,
		callback => $callback,
	);

	my $menu = Gtk::Menu->new;
	$menu->append($submenu);
	$menu->show;
	
	return $menu;
}

sub build_submenu {
	my $self = shift;
	my %par = @_;
	my ($parent, $callback) = @par{'parent','callback'};
	
	my $item = Gtk::MenuItem->new ($parent->name);
	$item->show;
	$item->signal_connect ("activate", sub { &$callback($parent->id) } );
	
	if ( not $parent->leaf ) {
		my $childs = JaM::Folder->query (
			where => "parent_id=?",
			params => [ $parent->id ]
		);

		my $menu = Gtk::Menu->new;
		$menu->show;
		$item->set_submenu($menu);

		my $drop_here = Gtk::MenuItem->new ("[Drop here]");
		$drop_here->signal_connect ("activate", sub { &$callback($parent->id) } );
		$drop_here->show;
		$menu->append($drop_here);

		foreach my $folder ( sort { $a->path cmp $b->path} values %{$childs} ) {
			my $item = $self->build_submenu (
				parent => $folder,
				callback => $callback,
			);
			$menu->append($item);
		}
	}
	
	return $item;
}

sub cb_add_input_filter {
	my $self = shift;
	
	my $filter;
	eval { $filter = $self->comp('input_filter') };

	if ( not $filter ) {
	  	require JaM::GUI::InputFilter;
	  	$filter = JaM::GUI::InputFilter->new (
			dbh => $self->dbh,
		);
		$filter->build;
	}
	
	$filter->add_new_filter (
		folder_object => $self->popup_folder_object
	);
	
	$filter->gtk_win->focus(1);
	
	1;
}

1;
