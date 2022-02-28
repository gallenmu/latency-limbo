create temp view export as

WITH

pre AS (
	SELECT ts, hdr
	FROM pkt
	JOIN capture USING (capture_id)
	WHERE
		capture.name = :'name'
		AND capture."type" = 'pre'
),
post AS (
	SELECT ts, hdr
	FROM pkt
	JOIN capture USING (capture_id)
	WHERE
		capture.name = :'name'
		AND capture."type" = 'post'
),

-- calc minima
premin AS (
	SELECT MIN(ts)
	FROM pre
),
postmin AS (
	SELECT MIN(ts)
	FROM post
),

-- count packets
postcount AS (
	SELECT COUNT(*) AS postc
	FROM post
),
precount AS (
	SELECT COUNT(*) AS prec
	FROM pre
),


-- NOTE: trimming happens independent for pre and post, i.e. there might be packets trimmed from pre that were received in post
pretrimmed AS (
	SELECT ts, hdr
	FROM pre
	WHERE pre.ts >= (1000000::bigint * (:'trim_ms')::bigint + (SELECT * from premin))::bigint
),
posttrimmed AS (
	SELECT ts, hdr
	FROM post
	WHERE post.ts >= (1000000::bigint * (:'trim_ms')::bigint + (SELECT * from postmin))::bigint
),

-- count packets (trimmed)
postcounttrimmed AS (
	SELECT COUNT(*) AS countposttrimmed
	FROM posttrimmed
),
precounttrimmed AS (
	SELECT COUNT(*) AS countpretrimmed
	FROM pretrimmed
)

-- output selection
SELECT
	precount.prec AS pre_received,
	postcount.postc AS post_received,
	precounttrimmed.countpretrimmed AS pre_received_trimmed,
	postcounttrimmed.countposttrimmed AS post_received_trimmed
FROM precount, postcount, precounttrimmed, postcounttrimmed
;

\copy (select * from export) to pstdout csv header
