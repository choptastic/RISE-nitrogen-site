-record(db_group,{id, name, subgroups}).
-record(db_contact,{id, name, email, phone, photo="undefined.png", bitmessage, address, my=false}).
-record(db_task,{id, due, name, text, parent, status=new}).
-record(db_file,{id, path, type, user, date, status, size}).
-record(db_expense,{id, name, date, type, text, amount, status, to, from}).
-record(db_update,{id, subject, from, text, date, status}).
-record(db_contact_roles,{id, type, tid, role, contact}).
-record(db_attachment,{id, file, type, tid}).
-record(db_group_members, {group, contact}).
