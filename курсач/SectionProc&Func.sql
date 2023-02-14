--GET ALL
CREATE OR REPLACE FUNCTION get_sections() 
RETURNS TABLE(
	id int4,
	section_name text,
	order_number int4
	)
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		s.id,
		s.section_name,
		s.order_number
	FROM section s
	ORDER BY s.order_number ASC;
	
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception in `get_setcions()` function:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- GET BY ID
CREATE OR REPLACE FUNCTION get_section(section_id int4)
RETURNS TABLE(
	id int4,
	section_name text,
	order_number int4
	)
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		s.id,
		s.section_name,
		s.order_number
	FROM section s
	WHERE s.id = section_id;
	
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception in `get_sections(integer)` function:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- ADD WITHOUT ORDER
CREATE OR REPLACE FUNCTION add_section(name text, user_id int) RETURNS boolean
AS $$
BEGIN
	IF NOT is_admin(user_id)
	THEN
		RAISE NOTICE E'Seems, this user doesn`t have enough rights to create new section'; 
		RETURN false;
	END IF;
	
	INSERT INTO section(section_name)
	VALUES
		(name);
	
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
CREATE OR REPLACE FUNCTION add_section(name text, order_nmb int4, user_id int4) RETURNS boolean
AS $$
BEGIN
	IF NOT is_admin(user_id)
	THEN
		RAISE NOTICE E'Seems, this user doesn`t have enough rights to create new section'; 
		RETURN false;
	END IF;

	INSERT INTO section(section_name, order_number)
	VALUES
		(name, order_nmb);
	
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

-- UPDATE NAME
CREATE OR REPLACE FUNCTION update_section(section_id int4, name text, user_id int4) RETURNS boolean
AS $$
DECLARE
	affected_rows int4;
BEGIN
	IF NOT is_admin(user_id)
	THEN
		RAISE NOTICE E'Seems, this user doesn`t have enough rights to update sections'; 
		RETURN false;
	END IF;
	WITH rows AS(
		UPDATE section 
		SET section_name = name
		WHERE id = section_id
		RETURNING 1
	) SELECT COUNT(*) into affected_rows FROM rows;
	
	IF affected_rows = 0
	THEN
		RAISE NOTICE E'No rows affected, probably wrong section_id'; 
		RETURN false;
	END IF;
	
	
	RETURN true;
	exception when others then 
		raise notice E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- UPDATE ORDER
CREATE OR REPLACE FUNCTION update_section(section_id int4, order_nmb int4, user_id int4) RETURNS boolean
AS $$
DECLARE
	affected_rows int4;
BEGIN
	IF NOT is_admin(user_id)
	THEN
		RAISE NOTICE E'Seems, this user doesn`t have enough rights to update sections'; 
		RETURN false;
	END IF;

	WITH rows AS(
		UPDATE section 
		SET order_number = order_nmb
		WHERE id = section_id
		RETURNING 1
	) SELECT COUNT(*) into affected_rows FROM rows;
	
	IF affected_rows = 0
	THEN
		RAISE NOTICE E'No rows affected, probably wrong section_id'; 
		RETURN false;
	END IF;
	
	RETURN true;
	exception when others then 
		raise notice E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;


-- DELETE 
CREATE OR REPLACE FUNCTION delete_section(section_id int4, user_id int4) RETURNS boolean
AS $$
DECLARE
	affected_rows int4;
BEGIN
	IF NOT is_admin(user_id)
	THEN
		RAISE NOTICE E'Seems, this user doesn`t have enough rights to delete section'; 
		RETURN false;
	END IF;

	WITH rows AS(
		DELETE FROM section
		WHERE id = section_id
		RETURNING 1
	) SELECT COUNT(*) INTO affected_rows FROM rows;
	
	IF affected_rows = 0
	THEN
		RAISE NOTICE E'No rows affected, probably wrong section_id'; 
		RETURN false;
	END IF;
	
	RETURN true;
	exception when others then 
		raise notice E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- GET SECTIONS DETAIL
CREATE OR REPLACE FUNCTION get_sections_detail() RETURNS TABLE(
	id int4,
	section_name text,
	order_number int4,
	forum_id int4,
	forum_order int4,
	forum_name text,
	forum_img_filename text,
	last_topic_id int4,
	post_count bigint,
	topic_count bigint
)
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		s.id,
		s.section_name,
		s.order_number,
		f.id,
		f.order_number,
		f.forum_name,
		fi.filename,
		(SELECT v.forum_id
		FROM post_with_topic_and_forum v
		WHERE v.forum_id = f.id
		ORDER BY v.creation_time DESC
		LIMIT 1),
		(SELECT COUNT(*)
		FROM post_with_topic_and_forum v
		WHERE v.forum_id = f.id),
		(SELECT COUNT(*)
		FROM topic tt 
		WHERE tt.forum_id = f.id)
		FROM section s
		LEFT JOIN forum f
			ON f.section_id = s.id
		LEFT JOIN forum_img fi
			ON fi.id = f.id
		ORDER BY s.order_number, f.order_number ASC;
	
	EXCEPTION WHEN others THEN 
		raise notice E'Got exception:
		FUNCTION: `get_sections_detail`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
END
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;



-- some things
select * from post;

---- tests

select * from get_sections();
select * from get_section(1);
select * from register('wer','wer','wer');
select * from login('wer', 'wer');
select * from get_all_user_detail();
select * from get_user_detail(1);

select * from add_section('test section');
select * from add_section('test section', 1);

select * from update_section(1, 'some name', 1);
select * from update_section(1, 3, 1);
select * from delete_section(1, 1);

select * from get_sections_detail();



