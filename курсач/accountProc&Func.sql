-- GET USER DETAIL
CREATE OR REPLACE FUNCTION get_user_detail(user_id int4) RETURNS TABLE(
	id int4,
	login text,
	username text,
	img_filename text,
	reg_date timestamp,
	role_id int4,
	role_name text,
	role_right_level int4,
	post_count bigint,
	topic_count bigint
)
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		a.id,
		a.login,
		ai.username,
		aimg.filename,
		ai.reg_date,
		r.id,
		r.name,
		r.right_level,
		(SELECT COUNT(*) 
		 FROM post p
		 WHERE p.sender_id = a.id),
		 (SELECT COUNT(*) 
		 FROM topic t
		 WHERE t.author_id = a.id)
	FROM account a
	LEFT JOIN account_info ai
		ON ai.id = a.id
	LEFT JOIN role r
		ON r.id = a.role_id
	LEFT JOIN account_img aimg
		ON aimg.id = a.id
	WHERE a.id = user_id;
		
	exception when others then 
		raise notice E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;
  

-- GET ALL USER DETAIL
CREATE OR REPLACE FUNCTION get_all_user_detail() RETURNS TABLE(
	id int4,
	login text,
	username text,
	filename text,
	reg_date timestamp,
	role_id int4,
	role_name text,
	role_right_level int4,
	post_count bigint,
	topic_count bigint
)
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		a.id,
		a.login,
		ai.username,
		aimg.filename,
		ai.reg_date,
		r.id,
		r.name,
		r.right_level,
		(SELECT COUNT(*) 
		 FROM post p
		 WHERE p.sender_id = a.id),
		 (SELECT COUNT(*) 
		 FROM topic t
		 WHERE t.author_id = a.id)
	FROM account a
	LEFT JOIN account_info ai
		ON ai.id = a.id
	LEFT JOIN role r
		ON r.id = a.role_id
	LEFT JOIN account_img aimg
		ON aimg.id = a.id;
		
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
END;
$$ LANGUAGE plpgsql;

-- IS ADMIN
CREATE OR REPLACE FUNCTION is_admin(user_id int4) RETURNS boolean
AS $$
BEGIN
	IF EXISTS (SELECT r.right_level 
		FROM account a 
	   	JOIN role r
			ON r.id = a.role_id AND r.right_level BETWEEN 0 AND 1
		WHERE a.id = user_id )
	THEN
		RETURN true;
	END IF;
	
	RETURN false;
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception in `is_admin` function:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;


--tests 

select * from get_user_detail(1);
select * from get_all_user_detail();
