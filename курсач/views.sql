-- some things
/*

select * from post;
select * from forum;
select * from topic;

*/
-- POST WITH TOPICS AND FORUMS
--DROP VIEW post_with_topic_and_forum;

CREATE OR REPLACE VIEW post_with_topic_and_forum
AS
SELECT 
	p.id,
	p.sender_id,
	p.creation_time,
	f.section_id,
	t.forum_id,
	p.topic_id
FROM post p
JOIN topic t
	ON t.id = p.topic_id
JOIN forum f
	ON f.id = t.forum_id;

-- POST WITH TOPICS