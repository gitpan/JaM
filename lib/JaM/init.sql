#<init>#

# create tables an indices

create table Folder (
	id		integer		primary key
					auto_increment
					not null,
	name		varchar(40)	not null,
	parent_id	integer		not null default 0,
	sibling_id	integer		not null default 99999,
	leaf		integer		default 0,
	path		varchar(255)	not null,
	selected_mail_id integer,
	mail_sum	integer		default 0,
	mail_read_sum	integer		default 0,
	status		varchar(32)	default 'R' not null,
	opened		integer		default 1,
	sort_column	integer		default 3,
	sort_direction	varchar(32)	default 'descending',
	show_max	integer		default 500,
	show_all	integer		default 0
);

create index Folder_idx1 on Folder(name);
create index Folder_idx2 on Folder(parent_id);
create unique index Folder_idx3 on Folder(path);
create index Folder_idx4 on Folder(sibling_id);

create table Account (
	id		integer		primary key
					auto_increment
					not null,
	from_name	varchar(255),
	from_adress	varchar(255),
	pop3_login	varchar(255),
	pop3_password	varchar(255),
	pop3_server	varchar(255),
	pop3_delete	integer		default 0,
	smtp_server	varchar(255),
	default_account	integer 	default 0
);

create table Mail (
	id		integer		primary key
					auto_increment
					not null,
	subject		varchar(255),
	sender		varchar(80)	not null,
	recipient	varchar(80),
	date		datetime	not null,
	folder_id	integer		not null,
	account_id	integer		not null,
	status		varchar(32)	default 'N' not null
);

create index Mail_idx1 on Mail(folder_id, date);
create index Mail_idx2 on Mail(folder_id, subject);
create index Mail_idx3 on Mail(folder_id, recipient);

create table Entity (
	id		integer		primary key
					auto_increment
					not null,
	mail_id		integer		not null,
	data		mediumblob
);

create index Entity_idx1 on Entity(mail_id);

create table Config (
	name		varchar(255) 	primary key
					not null,
	description	varchar(255)	not null,
	value		text,
	visible		integer		default 1,
	type		varchar(32)	default 'text'
);

create index Config_idx1 on Config(description);

create table IO_Filter (
	id		integer		primary key
					auto_increment
					not null,
	name		varchar(255)	not null,
	object		mediumblob,
	sortkrit	integer,
	output		integer,
	last_changed	integer
);

create index IO_Filter_idx1 on IO_Filter(last_changed);
create index IO_Filter_idx2 on IO_Filter(name);

create table View_Filter (
	id		integer		primary key
					auto_increment
					not null,
	name		varchar(255)	not null,
	object		mediumblob,
	last_changed	integer
);

create index View_Filter_idx1 on View_Filter(last_changed);
create index View_Filter_idx2 on View_Filter(name);

create table Folder2View_Filter (
	folder_id	integer		not null,
	view_filter_id	integer		not null
);

create unique index Folder2View_Filter_idx1 on Folder2View_Filter (folder_id, view_filter_id);
create index Folder2View_Filter_idx2 on Folder2View_Filter (view_filter_id);
create index Folder2View_Filter_idx3 on Folder2View_Filter (folder_id);

# create configuration parameters

insert into Config (name, description, value, visible, type)
values ('quoted_color', 'Quoted Text Color', '#aa0000', 1, 'html_color');

insert into Config (name, description, value, visible, type)
values ('subject_sort_column', '', '3', 0, '');

insert into Config (name, description, value, visible, type)
values ('subject_sort_direction', '', 'descending', 0, '');

insert into Config (name, description, value, visible, type)
values ('mail_target_dir', 'Default Mail Target Dir', '/tmp', 1, 'dir');

insert into Config (name, description, value, visible, type)
values ('attachment_target_dir', 'Default Attachment Target Dir', '/tmp', 1, 'dir');

insert into Config (name, description, value, visible, type)
values ('attachment_source_dir', 'Default Attachment Source Dir', '/tmp', 1, 'dir');

insert into Config (name, description, value, visible, type)
values ('no_reply_addresses', 'Dont Reply To This Adresses', "[ 'joern@netcologne.de', 'joern@zyn.de', 'joern@dimedis.de' ]", 1, 'list');

insert into Config (name, description, value, visible, type)
values ('smtp_hello', 'SMTP Hello String', 'wizard.castle', 1, 'text');

insert into Config (name, description, value, visible, type)
values ('sent_folder_id', '', '3', 0, '');

insert into Config (name, description, value, visible, type)
values ('trash_folder_id', '', '5', 0, '');

insert into Config (name, description, value, visible, type)
values ('x_mailer', '', 'JaM - Just a Mailer (Highly Secure Personal Free Highspeed Archiving Gtk Perl Mailer Against Micro$oftism)', 0, 'text');

insert into Config (name, description, value, visible, type)
values ('program_name', '', 'JaM - Just a Mailer', 0, 'text');

insert into Config (name, description, value, visible, type)
values ('html2ps_prog', 'Path Of html2ps Program', '/usr/bin/html2ps', 1, 'file');

insert into Config (name, description, value, visible, type)
values ('lpr_prog', 'Path Of lpr Program', '/usr/bin/lpr', 1, 'file');

insert into Config (name, description, value, visible, type)
values ('printer_name', 'Printer Name', 'lp', 1, 'text');

insert into Config (name, description, value, visible, type)
values ('folders_width', '', '230', 0, '');

insert into Config (name, description, value, visible, type)
values ('subjects_height', '', '200', 0, '');

insert into Config (name, description, value, visible, type)
values ('main_window_width', '', '940', 0, '');

insert into Config (name, description, value, visible, type)
values ('main_window_height', '', '800', 0, '');

insert into Config (name, description, value, visible, type)
values ('folders_column_0', '', '130', 0, '');

insert into Config (name, description, value, visible, type)
values ('folders_column_1', '', '40', 0, '');

insert into Config (name, description, value, visible, type)
values ('folders_column_2', '', '30', 0, '');

insert into Config (name, description, value, visible, type)
values ('subjects_column_0', '', '40', 0, '');

insert into Config (name, description, value, visible, type)
values ('subjects_column_1', '', '350', 0, '');

insert into Config (name, description, value, visible, type)
values ('subjects_column_2', '', '150', 0, '');

insert into Config (name, description, value, visible, type)
values ('subjects_column_3', '', '40', 0, '');

insert into Config (name, description, value, visible, type)
values ('folder_tree_left', 'Place Folder Tree Left', '1', 1, 'bool');

insert into Config (name, description, value, visible, type)
values ('font_name_fixed', 'Fixed Font', '-*-courier-medium-r-*-*-*-120-*-*-*-*-*-*', 1, 'font');

insert into Config (name, description, value, visible, type)
values ('font_name_fixed_bold', 'Fixed Font Bold', '-*-courier-bold-r-*-*-*-120-*-*-*-*-*-*', 1, 'font');

insert into Config (name, description, value, visible, type)
values ('font_name_folder_read', 'Folder Read Font', '-*-helvetica-medium-r-*-*-*-100-*-*-*-*-*-*', 1, 'font');

insert into Config (name, description, value, visible, type)
values ('font_name_folder_unread', 'Folder Unread Font', '-*-helvetica-bold-r-*-*-*-100-*-*-*-*-*-*', 1, 'font');

insert into Config (name, description, value, visible, type)
values ('folder_unread_child_color', 'Color of folders with unread child folders', '#666666', 1, 'html_color');

insert into Config (name, description, value, visible, type)
values ('font_name_mail_read', 'Mail Read Font', '-*-helvetica-medium-r-*-*-*-120-*-*-*-*-*-*', 1, 'font');

insert into Config (name, description, value, visible, type)
values ('font_name_mail_unread', 'Mail Unread Font', '-*-helvetica-bold-r-*-*-*-120-*-*-*-*-*-*', 1, 'font');

insert into Config (name, description, value, visible, type)
values ('font_name_mail_compose', 'Mail Compose Font', '-*-courier-medium-r-*-*-*-120-*-*-*-*-*-*', 1, 'font');

insert into Config (name, description, value, visible, type)
values ('database_schema_version', '', '0', 0, '');

# create basic data --------------------------------------------------

insert into Account (id, from_name, from_adress, pop3_login, pop3_password, pop3_server, pop3_delete, smtp_server, default_account)
values (1, '','','','','',0,'', 1);

insert into Folder (id, name, parent_id, leaf, path, sibling_id)
values (1, 'Mail', 0, 0, '/', 99999);

insert into Folder (id, name, parent_id, leaf, path, sibling_id)
values (2, 'Inbox', 1, 1, '/Inbox', 3);

insert into Folder (id, name, parent_id, leaf, path, sibling_id)
values (3, 'Sent', 1, 1, '/Sent', 4);

insert into Folder (id, name, parent_id, leaf, path, sibling_id)
values (4, 'Drafts', 1, 1, '/Drafts', 5);

insert into Folder (id, name, parent_id, leaf, path, sibling_id)
values (5, 'Trash', 1, 1, '/Trash', 6);

insert into Folder (id, name, parent_id, leaf, path, sibling_id)
values (6, 'Templates', 1, 1, '/Templates', 99999);

#</init>#

# Statements for updating versions -----------------------------------

# each section is enclosed with
# #<versionNUMBER># ... #</versionNUMBER>#
