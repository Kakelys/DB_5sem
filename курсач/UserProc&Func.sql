
DROP FUNCTION register();
DROP FUNCTION is_user_exist;


-- IS USER EXIST
CREATE OR REPLACE FUNCTION is_user_exist(login_name text) 
RETURNS boolean
AS $$
BEGIN
	IF EXISTS (
		SELECT FROM account a 
		WHERE a.login = login_name
	)
	THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
END
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;


-- FUNCTION FOR REGISTER
CREATE OR REPLACE FUNCTION register(login_name text, name text, pwd text) 
RETURNS TABLE(
	id int4,
	username text,
	login text,
	role_id int4,
	reg_date timestamp) 
AS $$
DECLARE 
	default_role_id int4;
	u_id int4;
	u_reg_date timestamp;
BEGIN
	IF is_user_exist(login_name)
	THEN
		RAISE NOTICE E'Account with same login already exist';
		RETURN;
	END IF;
	
	SELECT r.id into default_role_id FROM role r WHERE r.name = 'user';
	
	INSERT INTO account(login, passwd, role_id)
	VALUES
		(login_name, pwd, default_role_id)
	RETURNING 
		account.id INTO u_id;
		
	INSERT INTO account_info(id, username)
	VALUES
		(u_id, name)
	RETURNING
		account_info.reg_date INTO u_reg_date;

	RETURN QUERY SELECT
		u_id,
		name,
		login_name,
		default_role_id,
		u_reg_date;
	EXCEPTION WHEN others THEN 
		raise notice E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;


-- FUNCTION LOGIN
CREATE OR REPLACE FUNCTION login(login_name text, pwd text)
RETURNS TABLE(
	id int4,
	username text,
	login text,
	role_id int4,
	reg_date timestamp) 
AS $$
BEGIN
	
	RETURN QUERY 
	SELECT 
		ac.id,
		aci.username,
		ac.login,
		ac.role_id,
		aci.reg_date
	FROM account ac
	JOIN role r
		ON r.id = ac.role_id
	JOIN account_info aci
		ON aci.id = ac.id
	WHERE ac.login = login_name AND ac.passwd = pwd;
	

	exception when others then 
		raise notice E'Got exception:
        SQLSTATE: % 
        SQLERRM: %', SQLSTATE, SQLERRM;  
END;
$$ LANGUAGE plpgsql
	SECURITY DEFINER
	SET search_path = public;
