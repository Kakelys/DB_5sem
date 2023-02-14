-- GET BY SECTIONS ID
CREATE OR REPLACE FUNCTION get_forums(sect_id int4) RETURNS TABLE (
	id int,
	forum_name text,
	last_post_id int4,
	post_count bigint,
	topic_count bigint
)
AS $$
BEGIN
	RETURN QUERY
	SELECT 
	f.id,
	f.forum_name,
	(	SELECT v.id
		FROM post_with_topic_and_forum v
		WHERE v.forum_id = f.id
		ORDER BY v.creation_time DESC
		LIMIT 1
	),
	(	SELECT COUNT(*)
		FROM post_with_topic_and_forum v
		WHERE v.forum_id = f.id
	),
	(	SELECT COUNT(*)
		FROM topic tt 
		WHERE tt.forum_id = f.id
	)
	FROM forum f
	WHERE f.section_id = sect_id;
	
	exception when others then 
		raise notice E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- ADD WITHOUT ORDER
CREATE OR REPLACE FUNCTION add_forum(sect_id int4, name text, user_id int4) RETURNS BOOLEAN
AS $$
BEGIN
	IF NOT is_admin(user_id)
	THEN
		RAISE NOTICE E'Seems, this user doen`t have enough rights to create new forum ';
	RETURN false;
	END IF;

	INSERT INTO forum(forum_name, section_id)
	values
		(name, sect_id);
	
	RETURN true;
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- ADD WITH ORDER
CREATE OR REPLACE FUNCTION add_forum(sect_id int4,name text, order_nmb int4, user_id int4) RETURNS BOOLEAN
AS $$
BEGIN
	IF NOT is_admin(user_id)
	THEN
		RAISE NOTICE E'Seems, this user doen`t have enough rights to create new forum ';
	RETURN false;
	END IF;

	INSERT INTO forum(forum_name, section_id, order_number)
	values
		(name, sect_id, order_nmb);
	
	RETURN true;
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;


-- DELETE
CREATE OR REPLACE FUNCTION delete_forum(forum_id int4, user_id int4) RETURNS BOOLEAN
AS $$
DECLARE
	affected_rows int4;
BEGIN
	IF NOT is_admin(user_id)
	THEN
		RAISE NOTICE E'Seems, this user doen`t have enough rights to create new forum ';
	RETURN false;
	END IF;	

	WITH rows AS (
		DELETE FROM forum 
		WHERE id = forum_id
		RETURNING 1
	) SELECT COUNT(*) INTO affected_rows FROM rows;
	
	IF affected_rows = 0
	THEN
		RAISE NOTICE E'No rows affected, probably wrong `forum_id`';
		RETURN false;
	END IF;
	
	RETURN true;
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- UPDATE FORUM SECTION ID
CREATE OR REPLACE FUNCTION update_forum(forum_id int4, sect_id int4, user_id int4) RETURNS BOOLEAN
AS $$
BEGIN
	IF NOT is_admin(user_id)
	THEN
		RAISE NOTICE E'Seems, this user doen`t have enough rights to edit forum ';
		RETURN false;
	END IF;
	
	-- check section exist
	IF (SELECT COUNT(*) FROM section s WHERE s.id = sect_id) = 0
	THEN
		RAISE NOTICE E'Section with this id doesn`t exist';
		RETURN false;
	END IF;
	
	-- check forum exist
	IF (SELECT COUNT(*) FROM forum f WHERE f.id = forum_id) = 0
	THEN
		RAISE NOTICE E'Forum with this id doesn`t exist';
		RETURN false;
	END IF;
	
	UPDATE forum
	SET "section_id" = sect_id
	WHERE "id" = forum_id;
	
	RETURN true;
	exception when others then 
		raise notice E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- UPDATE FORUM NAME
CREATE OR REPLACE FUNCTION update_forum(forum_id int4, name text, user_id int4) RETURNS BOOLEAN
AS $$
DECLARE
	affected_rows int4;
BEGIN
	IF NOT is_admin(user_id)
	THEN
		RAISE NOTICE E'Seems, this user doen`t have enough rights to edit forum ';
	RETURN false;
	END IF;
	
	WITH rows AS (
	UPDATE forum 
	SET "forum_name" = name
	WHERE "id" = forum_id
	RETURNING 1
	) SELECT COUNT(*) INTO affected_rows FROM rows;
	
	IF affected_rows = 0
	THEN
		RAISE NOTICE E'No rows affected, probably wrong `forum_id`';
		RETURN false;
	END IF;
	
	RETURN true;
	exception when others then 
		raise notice E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- UPDATE ORDER
CREATE OR REPLACE FUNCTION update_forum_order(forum_id int4, order_nmb int4, user_id int4) RETURNS BOOLEAN
AS $$
DECLARE
	affected_rows int4;
BEGIN
	IF NOT is_admin(user_id)
	THEN
		RAISE NOTICE E'Seems, this user doen`t have enough rights to edit forum';
		RETURN false;
	END IF;
	
	WITH rows AS(
		UPDATE forum
		SET order_number = order_nmb
		WHERE id = forum_id
		RETURNING 1
	) SELECT COUNT(*) INTO affected_rows FROM rows;
	
	IF affected_rows = 0
	THEN
		RAISE NOTICE E'No rows affected, probably wrong `forum_id`';
		RETURN false;
	END IF;
	
	RETURN true;
	exception when others then 
		raise notice E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- TESTS

select * from get_sections();
select * from get_sections_detail();

select * from add_section('another section', 1);

select * from add_forum(3, 'one', 1);
select * from add_forum(2, 'two', 1);
select * from add_forum(3, 'two', 1);
select * from add_forum(3, 'two', 2);

select * from update_forum(2, 'new name', 1);
select * from update_forum(2, 3, 1);
select * from update_forum_order(2, 1, 1);

select * from delete_forum(4,1);

