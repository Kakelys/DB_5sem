-- GET USER IMG
CREATE OR REPLACE FUNCTION get_account_img(user_id int4) RETURNS TABLE(
	id int4,
	filename text
)
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		ai.id,
		ai.filename
	FROM account_img ai
	WHERE ai.id = user_id;
	
	EXCEPTION WHEN others THEN 
		RAISE NOTICE E'Got exception:
		FUNCTION: get_account_img
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;


-- ADD OR UPDATE USER IMG 
CREATE OR REPLACE FUNCTION update_account_img(user_id int4, path text) RETURNS boolean
AS $$
DECLARE
	affected_rows int4;
BEGIN
	IF EXISTS (SELECT 1 
			  FROM account_img ai 
			  WHERE ai.id = user_id  )
	THEN
		WITH rows AS(
			UPDATE account_img
			SET filename = path 
			WHERE id = user_id
			RETURNING 1
		) SELECT COUNT(*) INTO affected_rows FROM rows;
		
	ELSE
		WITH rows AS(
			INSERT INTO account_img
			VALUES
				(user_id, path)
			RETURNING 1
		) SELECT COUNT(*) INTO affected_rows FROM rows;
	END IF;
	
	IF affected_rows = 0
	THEN
		RAISE NOTICE E'No rows affected, probably worng `user_id`';
		RETURN false;
	END IF;
	
	
	RETURN true;
	EXCEPTION WHEN others THEN  
		raise notice E'Got exception:
		FNCTION: `update_account_img`
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
		
		RETURN false;
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;

-- ADD OR UPDATE FORUM IMG 
CREATE OR REPLACE FUNCTION update_forum_img(forum_id int4, path text, user_id int4) RETURNS boolean
AS $$
BEGIN
	IF NOT is_admin(user_id)
	THEN
		RAISE NOTICE E'Seems, user doesn`t have enough rights to update forum image';
		RETURN false;
	END IF;
	
	IF EXISTS (SELECT 1 
			  FROM forum_img fi 
			  WHERE fi.id = forum_id  )
	THEN
		UPDATE forum_img fi
		SET fi.filename = path 
		WHERE fi.id = forum_id;
	ELSE
		INSERT INTO forum_img
		VALUES
			(forum_id, path);
		
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

-- tests

select * from account;
select * from 
select * from register('wer','wer','wer');
select * from account;
select update_account_img(1, 'somefile.png');
select update_forum_img();


