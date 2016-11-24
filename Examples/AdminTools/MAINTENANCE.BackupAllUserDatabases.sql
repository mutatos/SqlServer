use Tools
go
if not exists (select schema_name from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME = 'MAINTENANCE')
begin
	exec sp_executesql N'create schema MAINTENANCE'
end
go


/*	MAINTENANCE.BackupAllUserDatabases

	Synopsis:			performs a full backup of every User DB on SQL Server Instance (version 2008 - 16)
	Input Parameter:	destination path, e.g. d:\backup
			 
	-- IMPORTANT: use Local Drives with adequate disk space and access permissions only (!)
*/
create proc MAINTENANCE.BackupAllUserDatabases  @inputBackupPath	nvarchar(255)
as
-- basic input validation
set @inputBackupPath = ltrim(rtrim(@inputBackupPath))

if (substring(@inputBackupPath, LEN(@inputBackupPath), 1) != '\')
begin
	set @inputBackupPath = @inputBackupPath + '\'
end

-- local vars used in routine
declare @DBName				nvarchar(256)	
declare @backupCommand		nvarchar(4000)

declare crUserDatabases cursor local fast_forward
for
	select name from sysdatabases 
	where sid != 0x01																-- optional: ignore System Databases, e.g. master, model, tempdb, msdb (adjust as needed)
																		

open crUserDatabases

fetch next from crUserDatabases into @DBName

while @@FETCH_STATUS = 0
begin

	-- BUILDING COMMAND STRING FOR DYNAMIC EXECUTION
	set @backupCommand =	'backup database [' + @DBName + '] to disk = '''		-- [] used to catch DB Names with special chars/spaces
							+ @inputBackupPath 
							+ replace(@DBName, ' ', '_')							-- avoid spaces in filename
							+ '_' + cast(datepart(yyyy, getdate()) as varchar(4))	-- Suffix _YYYY_MM_DD.bak
							+ '_' + cast(datepart(mm, getdate()) as varchar(2))		-- adjust as needed
							+ '_' + cast(datepart(dd, getdate()) as varchar(2)) 
							+ '.bak'''												-- note: '' escape sequence to indicate ' within string
							+ ' with copy_only'										-- do not interfere with standard routines, for details see https://msdn.microsoft.com/en-us/library/ms191495.aspx

	-- EXECUTE CONTENT OF STRING
	
	exec (@backupCommand)
	-- select @backupCommand														-- switch to display only for debugging

	fetch next from crUserDatabases into @DBName
end

close crUserDatabases			-- always close and deallocate cursor (!)
deallocate crUserDatabases

go

-- example
--exec Maintenance.BackupAllUserDatabases 'C:\Backup\Sql'
