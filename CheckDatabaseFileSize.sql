SELECT DB_ID() DatabaseID, FileID, DB_Name() DatabaseName, rtrim(name) FileLogicalName, 
groupid AS FileGroupID, 
filename AS FileFullPath,
cast(size/128.0 AS DECIMAL(19,2))								AS [FileSizeMB],		-- size, spaceused and maxsize are counted in Pages (8k) i.e PageCount / 128 = MB
cast(FILEPROPERTY(name, 'SpaceUsed')/128.0 AS DECIMAL(19,2))	AS [SpaceUsedMB],		-- SpaceUsed is the real space used within a DB File (rest zeros)
cast([maxsize]/128.0 AS DECIMAL(19,2))							AS [MaxFileSizeMB],		-- maxsize indicates the file size growth limit
Autogrowth = case when cast([maxsize]/128.0 AS DECIMAL(19,2)) < 0 then 1 else 0 end ,	-- Autogrowth is true if MaxFileSize is negative	
cast(available_bytes/1048576 AS decimal(19,2))					AS SpaceOnVolumeMB,		
CurrentExpansionLimitMB =	case --Determining Max Data Size (FileSize or Diskspace Limit)
							when cast([maxsize]/128.0 AS DECIMAL(19,2)) < 0 then cast(available_bytes/1048576 AS decimal(19,2)) -- if automatic growth, then volume size is limit
							when cast([maxsize]/128.0 AS DECIMAL(19,2)) > cast(available_bytes/1048576 AS decimal(19,2)) then cast(available_bytes/1048576 AS decimal(19,2)) -- special case: file size limit higher than disk space availabe (bad!) - in this case we use SpaceOnVolume as Limit
							else cast([maxsize]/128.0 AS DECIMAL(19,2)) end
FROM		sysfiles as dbStorageInfo										-- DB File Information	
cross apply sys.dm_os_volume_stats(DB_ID(), dbStorageInfo.fileid)			-- Disk Space Information
ORDER BY FileGroupID DESC, FileLogicalName ASC
