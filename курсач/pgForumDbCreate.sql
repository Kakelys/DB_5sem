/*
drop table role cascade;
drop table section cascade;
drop table topic cascade;
drop table forum cascade;
drop table post cascade; 
drop table ban cascade;
drop table account_img cascade;
drop table forum_img cascade;
drop table account cascade;
drop table account_info cascade;
*/
/*
DO
$do$
DECLARE
   _sql text;
BEGIN
   SELECT INTO _sql
          string_agg(format('DROP %s %s;'
                          , CASE prokind
                              WHEN 'f' THEN 'FUNCTION'
                              WHEN 'a' THEN 'AGGREGATE'
                              WHEN 'p' THEN 'PROCEDURE'
                              WHEN 'w' THEN 'FUNCTION'  -- window function (rarely applicable)
                              -- ELSE NULL              -- not possible in pg 11
                            END
                          , oid::regprocedure)
                   , E'\n')
   FROM   pg_proc
   WHERE  pronamespace = 'public'::regnamespace  -- schema name here!
   -- AND    prokind = ANY ('{f,a,p,w}')         -- optionally filter kinds
   ;

   IF _sql IS NOT NULL THEN
      RAISE NOTICE '%', _sql;  -- debug / check first
      -- EXECUTE _sql;         -- uncomment payload once you are sure
   ELSE 
      RAISE NOTICE 'No fuctions found in schema %', quote_ident(_schema);
   END IF;
END
$do$;
*/


create table role (
	id serial primary key,
	name text not null,
	right_level int4 not null
);

insert into role(right_level, name)
values
	(0,'admin'),
	(1,'moderator'),
	(10,'user');

create table account (
	id serial primary key,
	login text not null unique constraint account_login_unique,
	passwd text not null,
	role_id int4 constraint account_role_id_fk references role(id)
);

create table account_info (
	id serial primary key constraint account_info_id references account(id) on delete cascade,
	username text not null,
	reg_date timestamp default current_timestamp
);

create table section (
	id serial primary key,
	order_number int4 not null default 0,
	section_name text not null
);

create table forum (
	id serial primary key,
	forum_name text not null,
	order_number int4 not null default 0,
	section_id int4 constraint forum_section_id_fk references section(id) on delete cascade
);

create table topic (
	id serial primary key,
	header text not null,
	message text not null,
	creation_time timestamp default current_timestamp,
	is_closed boolean default false,
	is_pinned boolean default false,
	forum_id int4 constraint topic_forum_id_fk references forum(id) on delete cascade,
	author_id int4 constraint topic_author_id_fk references account(id)
);

create table post (
	id serial primary key,
	message text not null,
	topic_id int4 constraint post_topic_fk references topic(id) on delete cascade,
	creation_time timestamp default current_timestamp,
	sender_id int4 constraint post_sender_fk references account(id)
);

create table ban (
	id serial primary key,
	user_id int4 constraint ban_user_fk references account(id) on delete cascade,
	admin_id int4 constraint ban_admin_fk references account(id),
	reason text not null,
	ban_time timestamp not null,
	unban_time timestamp not null,
	is_perm boolean default false,
	is_active boolean default true
);

create table account_img (
	id int4 primary key references account(id) on delete cascade,
	filename text
);

create table forum_img (
	id int4 primary key references forum(id) on delete cascade,
	filename text
);

/*
GRANT SELECT, UPDATE, INSERT, DELETE ON ALL TABLES IN SCHEMA public TO root;
grant usage ON ALL SEQUENCES IN SCHEMA public TO root;
*/