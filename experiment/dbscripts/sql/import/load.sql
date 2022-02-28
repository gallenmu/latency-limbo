insert into capture (name, "type")
	values (:'name', :'type')
	returning capture_id as capture_id
\gset import_ 

create temporary table import (ts int8, hdr bytea);

\copy import from pstdin

insert into pkt (capture_id, ts, hdr) select :import_capture_id, ts, hdr from import;
