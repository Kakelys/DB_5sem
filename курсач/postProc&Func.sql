-- GET posts BY topic_id
CREATE OR REPLACE FUNCTION get_posts(tpc_id int4) RETURNS TABLE(
	id int4,
	topic_id int4,
	message text,
	creation_time timestamp,
	sender_id int4
)
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		p.id,
		p.topic_id,
		p.message,
		p.creation_time,
		p.sender_id
	FROM post p
	WHERE p.topic_id = tpc_id
	ORDER BY p.creation_time;	
	
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception in get_posts(integer) function:
		FUNCTION: `get_posts(int)`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- GET posts BY topic_id AND page AND amount_page 
CREATE OR REPLACE FUNCTION get_posts(tpc_id int4, page int4, post_amount int4) RETURNS TABLE(
	id int4,
	topic_id int4,
	message text,
	creation_time timestamp,
	sender_id int4
)
AS $$
BEGIN

	RETURN QUERY
	SELECT 
		p.id,
		p.topic_id,
		p.message,
		p.creation_time,
		p.sender_id
	FROM post p
	WHERE p.topic_id = tpc_id	
	ORDER BY p.creation_time
	LIMIT post_amount
	OFFSET ((page-1)*post_amount);
	
	EXCEPTION WHEN others THEN 
		RAISE NOTICE 
		E'Got exception:
		FUNCTION: `get_posts(int,int,int)`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- ADD POST to topic
CREATE OR REPLACE FUNCTION add_post(topic_id int4, user_id int4, message text) RETURNS boolean
AS $$
DECLARE
	affected_rows int4;
BEGIN
	
	IF is_topic_closed(topic_id)
	THEN
		RAISE INFO E'This topic closed and new posts cannot be added';
		RETURN false;
	END IF;
	
	WITH rows AS(
		INSERT INTO post("topic_id", "sender_id", "message")
		VALUES
			(topic_id, user_id, message)
		RETURNING 1
	) SELECT COUNT(*) into affected_rows from rows;
	
	IF affected_rows = 0
	THEN
		RAISE NOTICE E'No rows affected, probably wrong `topic_id`';
		RETURN false;
	END IF;
	
	RETURN true;
	EXCEPTION WHEN others THEN 
		RAISE LOG 
		E'Got exception:
		FUNCTION: `add_post`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;


-- DELETE POST
CREATE OR REPLACE FUNCTION delete_post(post_id int4, user_id int4) RETURNS boolean
AS $$
DECLARE
	affected_rows int4;
BEGIN
	IF NOT (is_admin(user_id) OR 
			(can_edit_post(post_id, user_id) AND NOT
				(SELECT t.is_closed
				FROM post p
				JOIN topic t
					ON t.id = p.topic_id
				WHERE p.id = post_id
				LIMIT 1
				)
			)
		   )
	THEN
		RAISE NOTICE E'Seems, user doesn`t have enough rights to delete post';
		RETURN false;
	END IF;

	WITH rows AS (
		DELETE 
		FROM post
		WHERE id = post_id
		RETURNING 1
	) SELECT COUNT(1) INTO affected_rows FROM rows;
	
	IF affected_rows = 0
	THEN
		RAISE NOTICE E'No rows affected, probably wrong `post_id`';
		RETURN false;
	END IF;
	
	RETURN true;
	EXCEPTION WHEN others THEN 
		RAISE NOTICE 
		E'Got exception:
		FUNCTION: `add_post`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- UPDATE POST message
CREATE OR REPLACE FUNCTION update_post(post_id int4, user_id int4, new_message text) RETURNS boolean
AS $$
DECLARE
	affected_rows int4;
BEGIN
	IF NOT ((can_edit_post(post_id, user_id) AND NOT
				(SELECT t.is_closed
				FROM post p
				JOIN topic t
					ON t.id = p.topic_id
				WHERE p.id = post_id
				LIMIT 1
				)
			)
		   )
	THEN
		RAISE NOTICE E'Seems, user doesn`t have enough rights to update post';
		RETURN false;
	END IF;

	WITH rows AS (
		UPDATE post
		SET message = new_message
		WHERE id = post_id
		RETURNING 1
	) SELECT COUNT(1) INTO affected_rows FROM rows;
	
	IF affected_rows = 0
	THEN
		RAISE NOTICE E'No rows affected, probably wrong `post_id`';
		RETURN false;
	END IF;
	
	RETURN true;
	EXCEPTION WHEN others THEN 
		RAISE NOTICE 
		E'Got exception:
		FUNCTION: `add_post`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- IS TOPIC CLOSED
CREATE OR REPLACE FUNCTION is_topic_closed(topic_id int4) RETURNS boolean
AS $$
BEGIN

	RETURN 
		(SELECT t.is_closed
		FROM topic t 
		WHERE t.id = topic_id
		LIMIT 1);

	EXCEPTION WHEN others THEN 
		RAISE NOTICE 
		E'Got exception:
		FUNCTION: `add_post`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- ACCESS TO EDIT
CREATE OR REPLACE FUNCTION can_edit_post(post_id int4, user_id int4) RETURNS boolean
AS $$
BEGIN
	IF (SELECT COUNT(*) 
	   	FROM post p
		WHERE p.id = post_id AND p.sender_id = user_id
	   ) > 0
	THEN
		RETURN true;
	END IF;
	
	RETURN false;
	EXCEPTION WHEN others THEN 
		RAISE NOTICE 
		E'Got exception:
		FUNCTION: `can_edit_post`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;



-- tests
select * from get_sections_detail();
select * from get_topics(3);
select update_topic_close(3, 1);
select * from get_posts(3);
select * from get_posts(6,1,5);
select add_post(3, 3, 'holla');

select update_post(1, 1, 'new message');

select delete_post(3, 1);
