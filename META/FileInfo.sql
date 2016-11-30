/*
	META.FileInfo

  Target:   SQL Server 2016
  Type:     VIEW
	Summary:	returns Data File, Real Space Used,  Max Size Limit, Space on Volume and the derived Column CurrentExpansionLimitMB per database

	Note:		
	Use CurrentExpansionLimitMB to evaluate free space for each file! MaxFileSizeMB can be higher than the available disk space and therefore is not a reliable indicator for file size limit.


*/
-- prep
if not exists (select schema_name from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME = 'META')
begin
	exec sp_executesql N'create schema META'
end
go
if (OBJECT_ID('META.FileInfo') is not null)
begin
	drop view META.FileInfo
end
go

-- create
create view META.FileInfo
as
SELECT DB_ID() DatabaseID, groupid FileGroupID, FileID, DB_Name() DatabaseName, rtrim(name) FileLogicalName, filename FileFullPath,
cast([size]/128.0 AS DECIMAL(19,2))                             AS [FileSizeMB],        -- size, spaceused and maxsize are counted in Pages (8k) i.e PageCount / 128 = MB
cast(FILEPROPERTY(name, 'SpaceUsed')/128.0 AS DECIMAL(19,2))    AS [SpaceUsedMB],       -- SpaceUsed is the real space used within a DB File (rest zeros)
cast([maxsize]/128.0 AS DECIMAL(19,2))                          AS [MaxFileSizeMB],     -- maxsize indicates the file size growth limit
cast(available_bytes/SQUARE(1024) AS decimal(19,2))                 AS SpaceOnVolumeMB,     
CurrentExpansionLimitMB =   case --Determining Max Data Size (FileSize or Diskspace Limit)
                            when cast([maxsize]/128.0 AS DECIMAL(19,2)) < 0 then cast(available_bytes/SQUARE(1024) AS decimal(19,2)) -- if unlimited growth, then volume size is limit
                            when cast([maxsize]/128.0 AS DECIMAL(19,2)) > cast(available_bytes/SQUARE(1024) AS decimal(19,2)) then cast(available_bytes/SQUARE(1024) AS decimal(19,2)) -- special case: file size limit higher than disk space availabe (bad!) - in this case we use SpaceOnVolume as Limit
                            else cast([maxsize]/128.0 AS DECIMAL(19,2)) end
FROM        sysfiles as dbStorageInfo                                       -- DB File Information  
cross apply sys.dm_os_volume_stats(DB_ID(), dbStorageInfo.fileid)           -- Disk Space Information
go


/*	Example

	select * from META.FileInfo
	order by FileID

*/
