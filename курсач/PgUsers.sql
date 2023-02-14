CREATE USER fuser with ENCRYPTED PASSWORD '.Qwerty1%';
CREATE USER fadmin with ENCRYPTED PASSWORD '.Qwerty1%';


select 
 * 
from information_schema.role_table_grants 
where grantee='fuser';

-- Masking 
COMMENT ON USER fuser IS 'MASKED';

-- USER GRANTS: 

	-- section
	GRANT 
		EXECUTE ON FUNCTION 
			public.get_section(int4),
			public.get_sections(),
			public.get_sections_detail(),
			public.get_forums(int4)
	TO fuser;

	-- post
	GRANT 
	EXECUTE ON FUNCTION 
		public.get_posts(int4),
		public.get_posts(int4, int4, int4),
		public.add_post(int4, int4, text),
		public.delete_post(int4, int4),
		public.update_post(int4, int4, text)
	TO fuser;
	
	-- topic
	GRANT 
	EXECUTE ON FUNCTION 
		public.get_topics(int4),
		public.get_topics(int4, int4, int4),
		public.add_topic(int4, int4, text, text),
		public.delete_topic(int4, int4),
		public.update_topic_close(int4, int4),
		public.update_topic_pin(int4, int4),
		public.update_topic_header(int4, int4, text),
		public.update_topic_message(int4, int4, text)
	TO fuser;
	
	-- user
	GRANT 
	EXECUTE ON FUNCTION 
		public.get_user_detail(int4),
		public.get_account_img(int4),
		public.login(text, text),
		public.register(text, text, text),
		public.update_account_img(int4, text)
	TO fuser;

-- ADMIN GRANTS:

	
	REVOKE ALL PRIVILEGES ON TABLE public.account FROM fuser;
	

select * from register('aaaa','a','a');
select * from login('aaaa', 'a');

select * from account;
grant all privileges on database forum to root;

