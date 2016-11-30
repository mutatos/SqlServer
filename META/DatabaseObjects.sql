/*
		META.DatabaseObjects

		Type:		VIEW
		Summary:	Full List of Database Objects with Schema Information

		Target:		SQL Server 2016
*/

if not exists (select schema_name from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME = 'META')
begin
	exec sp_executesql N'create schema META'
end
go
if (OBJECT_ID('META.DatabaseObjects') is not null)
begin
	drop view META.DatabaseObjects 
end
go

create view META.DatabaseObjects
as
select		'[' + ss.name + '].['  + so.name + ']'  FullName,  
			ss.name									SchemaName, 
			so.name									ObjectName,
			so.type									SystemTypeFlag,
			so.type_desc							TypeDescription,
			so.modify_date							LastChanged,
			ss.schema_id							SchemaID, 
			so.object_id							ObjectID,  
			so.parent_object_id						ParentObjectID
from			sys.schemas		ss
inner join		sys.objects		so		on	ss.schema_id = so.schema_id
go

/* EXAMPLE

	-- All User Objects
	select * from META.DatabaseObjects
	where SystemTypeFlag not in ('S', 'SQ', 'IT')
	order by LastChanged desc

	-- All Objects pertaining to Schema META
		select * from META.DatabaseObjects
		where SchemaName = 'META'

*/
