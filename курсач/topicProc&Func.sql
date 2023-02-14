-- GET TOPICS BY FORUM ID
CREATE OR REPLACE FUNCTION get_topics(frm_id int4) RETURNS TABLE(
	id int4,
	header text,
	message text,
	author_id int4,
	creation_time timestamp,
	forum_id int4,
	is_closed boolean,
	is_pinned boolean,
	post_count bigint,
	last_post_id int4
)
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		t.id,
		t.header,
		t.message,
		t.author_id,
		t.creation_time,
		t.forum_id,
		t.is_closed,
		t.is_pinned,
		(SELECT COUNT(*) 
		 FROM post p
		 WHERE p.topic_id = t.id),
		 (SELECT p.id
		 FROM post p 
		 WHERE p.topic_id = t.id
		 LIMIT 1)
	FROM topic t
	WHERE t.forum_id = frm_id
	ORDER BY 
		t.is_pinned DESC,
		t.creation_date DESC;
	
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception:
		FUNCTION: `get_topics(integer)`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- GET POSTS BY forum id with page AND amount posts ON PAGE
CREATE OR REPLACE FUNCTION get_topics(frm_id int4, page int4, amount_post int4) RETURNS TABLE(
	id int4,
	name text,
	message text,
	author_id int4,
	creation_time timestamp,
	forum_id int4,
	is_closed boolean,
	is_pinned boolean,
	post_count bigint,
	last_post_id int4
)
AS $$
BEGIN
	IF page < 1 OR amount_post < 1 
	THEN
			raise notice E'`page` and `amount_post` must be above 0 in get_topics function';
			RETURN;
	END IF;

	RETURN QUERY
	SELECT 
		t.id,
		t.header,
		t.message,
		t.author_id,
		t.creation_time,
		t.forum_id,
		t.is_closed,
		t.is_pinned,
		(SELECT COUNT(*) 
		 FROM post p
		 WHERE p.topic_id = t.id),
		 (SELECT p.id
		 FROM post p 
		 WHERE p.topic_id = t.id
		 LIMIT 1)
	FROM topic t
	WHERE t.forum_id = frm_id
	ORDER BY 
		t.is_pinned DESC,
		t.creation_date DESC
	LIMIT amount_post
	OFFSET ((page-1)*amount_post);
	
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception:
		FUNCTION: `get_topics(integer, integer, integer)`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;


-- ADD TOPIC 
CREATE OR REPLACE FUNCTION add_topic(forum_id int4, author_id int4, topic_header text, message text) RETURNS boolean
AS $$
BEGIN

	INSERT INTO topic("header", "message", "author_id", "forum_id") 
	VALUES 
		(topic_header, message, author_id, forum_id);
	
	RETURN true;
	EXCEPTION WHEN others THEN 
		raise notice E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- DELETE TOPIC
CREATE OR REPLACE FUNCTION delete_topic(topic_id int4, user_id int4) RETURNS boolean
AS $$
DECLARE
	affectedRows int4;
BEGIN
	IF NOT (is_admin(user_id) OR can_edit_topic(topic_id, user_id))
	THEN
		RAISE NOTICE E'Seems, user doesn`t have enough rights to delete topic this';
		RETURN false;
	END IF;


	WITH rows as (
		DELETE 
		FROM topic t
		WHERE t.id = topic_id
		RETURNING 1
	)
	SELECT COUNT(*) INTO affectedRows FROM rows;
	
	IF affectedRows = 0 THEN
		RAISE NOTICE E'No rows affected in delete_topic function, probably wrong topic id';
		RETURN false;
	END IF;
	
	
	RETURN true;
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception:
		FUNCTION: `delete_topic`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- UPDATE PIN STATE
CREATE OR REPLACE FUNCTION update_topic_pin(topic_id int4, user_id int4) RETURNS boolean
AS $$
DECLARE
	affectedRows int4;
BEGIN
	IF NOT (is_admin(user_id) OR can_edit_topic(topic_id, user_id))
	THEN
		RAISE NOTICE E'Seems, user doesn`t have enough rights to update topic state';
		RETURN false;
	END IF;
	
	WITH rows AS(
		UPDATE topic t
		SET is_pinned = NOT is_pinned
		where t.id = topic_id
		RETURNING 1
	) SELECT COUNT(*) INTO affectedRows FROM rows;
	
	IF affectedRows = 0
	THEN
		RAISE NOTICE E'No rows affected in update_topic_pin function, probably wrong id';
		RETURN false;
	END IF;
	
	RETURN true;
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception:
		FUNCTION: `update_topic_pin`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- UPDATE CLOSE STATE
CREATE OR REPLACE FUNCTION update_topic_close(topic_id int4, user_id int4) RETURNS boolean
AS $$
DECLARE
	affectedRows int4;
BEGIN
	IF NOT (is_admin(user_id) OR can_edit_topic(topic_id, user_id))
	THEN
		RAISE NOTICE E'Seems, user doesn`t have enough rights to update topic state';
		RETURN false;
	END IF;

	WITH rows AS(
		UPDATE topic t
		SET is_closed = NOT is_closed
		where "id" = topic_id
		RETURNING 1
	) SELECT COUNT(*) INTO affectedRows FROM rows;
	IF affectedRows = 0
	THEN
		raise notice E'No rows affected in update_topic_close function, probably wrong id';
		return false;
	END IF;
	
	RETURN true;
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception:
		FUNCTION: `update_topic_close`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- UPDATE HEADER
CREATE OR REPLACE FUNCTION update_topic_header(topic_id int4, user_id int4, new_header text) RETURNS boolean
AS $$
DECLARE
	affectedRows int4;
BEGIN
	IF NOT (is_admin(user_id) OR can_edit_topic(topic_id, user_id))
	THEN
		RAISE NOTICE E'Seems, user doesn`t have enough rights to update topic';
		RETURN false;
	END IF;

	WITH rows AS(
		UPDATE topic t
		SET header = new_header
		where "id" = topic_id
		RETURNING 1
	) SELECT COUNT(*) INTO affectedRows FROM rows;
	IF affectedRows = 0
	THEN
		raise notice E'No rows affected in update_topic_header function, probably wrong id';
		return false;
	END IF;
	
	RETURN true;
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception:
		FUNCTION: `update_topic_header`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- UPDATE HEADER
CREATE OR REPLACE FUNCTION update_topic_message(topic_id int4, user_id int4, new_message text) RETURNS boolean
AS $$
DECLARE
	affectedRows int4;
BEGIN
	IF NOT (is_admin(user_id) OR can_edit_topic(topic_id, user_id))
	THEN
		RAISE NOTICE E'Seems, user doesn`t have enough rights to update topic state';
		RETURN false;
	END IF;

	WITH rows AS(
		UPDATE topic t
		SET message = new_message
		where "id" = topic_id
		RETURNING 1
	) SELECT COUNT(*) INTO affectedRows FROM rows;
	
	IF affectedRows = 0
	THEN
		raise notice E'No rows affected in update_topic_message function, probably wrong `topic_id`';
		return false;
	END IF;
	
	RETURN true;
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception:
		FUNCTION: `update_topic_message`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- ACCESS TO EDIT 
CREATE OR REPLACE FUNCTION can_edit_topic(topic_id int4, user_id int4) RETURNS boolean
AS $$
BEGIN
	IF (SELECT COUNT(*) 
	   	FROM topic t
		WHERE t.id = topic_id AND t.author_id = user_id
	   ) > 0
	THEN
		RETURN true;
	END IF;
	
	RETURN false;
	EXCEPTION WHEN others THEN 
		RAISE NOTICE 
		E'Got exception:
		FUNCTION: `can_edit_topic`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- test
select * from get_sections_detail();
select * from get_all_user_detail();
select add_topic(3, 3, 'new topic', 'some message in the new topic');
select add_topic(3, 1, 'second', 'some message in the new topic');
select add_topic(3, 2, 'third', 'some message in the new topic');

select * from get_topics(3);
select * from get_topics(3,1,5);

select * from register('test','test','test');

select update_topic_pin(3,1);
select update_topic_close(3,1);
select update_topic_header(3, 3, '2new header');
select update_topic_message(3, 1, 'new message');

select delete_topic(9,1);
