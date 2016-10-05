-- All taken from this benchmark https://benchmarks.cisecurity.org/tools2/sqlserver/CIS_Microsoft_SQL_Server_2014_Benchmark_v1.2.0.pdf
SELECT '2.1' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'ad hoc distributed queries'
UNION
SELECT '2.2' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'clr enabled' 
UNION
SELECT '2.3' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Cross db ownership chaining'
UNION
SELECT '2.4' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Database Mail XPs'
UNION
SELECT '2.5' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Ole Automation Procedures'
UNION
SELECT '2.6' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Remote access'
UNION
SELECT '2.7' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Remote admin connections' AND SERVERPROPERTY('IsClustered') = 0
UNION
SELECT '2.8' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Scan for startup procs'


--Will display nothing if no databases are set to ON
SELECT '2.9' as 'CIS Benchmark Ref', name FROM sys.configurations WHERE is_trustworthy_on = 1 AND name != 'msdb' AND state = 0 ;


--very rarely works
DECLARE @getValue INT;
EXEC master..xp_instance_regread
@rootkey = N'HKEY_LOCAL_MACHINE',
@key = N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib',
@value_name = N'HideInstance',
@value = @getValue OUTPUT;
SELECT '2.12' as 'CIS Benchmark Ref', @getValue;

-- check if sa renamed and is disabled
SELECT '2.13 & 2.14' as 'CIS Benchmark Ref', name, is_disabled
FROM sys.server_principals
WHERE sid = 0x01; 

--is XP command disabled - ref 2.15
EXECUTE sp_configure 'show advanced options',1;
RECONFIGURE WITH OVERRIDE;
EXECUTE sp_configure 'xp_cmdshell'; 


SELECT '2.16' as 'CIS Benchmark Ref', name, containment, containment_desc, is_auto_close_on
FROM sys.databases
WHERE containment <> 0 and is_auto_close_on = 1; 

--ensure no other account has been created with a name of 'sa'
SELECT '2.17' as 'CIS Benchmark Ref', sid, name,
FROM sys.server_principals
WHERE L.name = 'sa'
AND L.sid <> 0x01; 

--ensure windows auth is in use - ref 3.1
xp_loginconfig 'login mode';

--no rows should be returned for this one
SELECT '3.2' as 'CIS Benchmark Ref', DB_NAME() AS DBName, dpr.name, dpe.permission_name
FROM sys.database_permissions dpe
JOIN sys.database_principals dpr
ON dpe.grantee_principal_id=dpr.principal_id
WHERE dpr.name='guest'
AND dpe.permission_name='CONNECT';

--orphaned users - ref 3.3
EXEC sp_change_users_login @Action='Report'; 

SELECT '3.4' as 'CIS Benchmark Ref', name AS DBUser
FROM sys.database_principals
WHERE name NOT IN ('dbo','Information_Schema','sys','guest')
AND type IN ('U','S','G')
AND authentication_type = 2;


SELECT '4.2' as 'CIS Benchmark Ref', l.[name], 'sysadmin membership' AS 'Access_Method'
FROM sys.sql_logins AS l
WHERE IS_SRVROLEMEMBER('sysadmin',name) = 1
AND l.is_expiration_checked <> 1
UNION ALL
SELECT l.[name], 'CONTROL SERVER' AS 'Access_Method'
FROM sys.sql_logins AS l
JOIN sys.server_permissions AS p
ON l.principal_id = p.grantee_principal_id
WHERE p.type = 'CL' AND p.state IN ('G', 'W')
AND l.is_expiration_checked <> 1;

SELECT '4.3' as 'CIS Benchmark Ref', name, is_disabled
FROM sys.sql_logins
WHERE is_policy_checked = 0; 

--very rarely works - ref 5.1
DECLARE @NumErrorLogs int;
EXEC master.sys.xp_instance_regread
N'HKEY_LOCAL_MACHINE',
N'Software\Microsoft\MSSQLServer\MSSQLServer',
N'NumErrorLogs',
@NumErrorLogs OUTPUT;
SELECT '5.1' as 'CIS Benchmark Ref', ISNULL(@NumErrorLogs, -1) AS [NumberOfLogFiles];


SELECT '5.2' as 'CIS Benchmark Ref', name,
 CAST(value as int) as value_configured,
 CAST(value_in_use as int) as value_in_use
FROM sys.configurations
WHERE name = 'Default trace enabled'; 

-- ref 5.3 should say failure
XP_loginconfig 'audit level'; 


SELECT '5.4' as 'CIS Benchmark Ref', S.name AS 'Audit Name'
, CASE S.is_state_enabled
WHEN 1 THEN 'Y'
WHEN 0 THEN 'N' END AS 'Audit Enabled'
, S.type_desc AS 'Write Location'
, SA.name AS 'Audit Specification Name'
, CASE SA.is_state_enabled
WHEN 1 THEN 'Y'
WHEN 0 THEN 'N' END AS 'Audit Specification Enabled'
, SAD.audit_action_name
, SAD.audited_result
FROM sys.server_audit_specification_details AS SAD
JOIN sys.server_audit_specifications AS SA
ON SAD.server_specification_id = SA.server_specification_id
JOIN sys.server_audits AS S
ON SA.audit_guid = S.audit_guid
WHERE SAD.audit_action_id IN ('CNAU', 'LGFL', 'LGSD');


SELECT '6.2' as 'CIS Benchmark Ref', name,
permission_set_desc
FROM sys.assemblies
where is_user_defined = 1; 


SELECT '7.1' as 'CIS Benchmark Ref', db_name() AS Database_Name, name AS Key_Name
FROM sys.symmetric_keys
WHERE algorithm_desc NOT IN ('AES_128','AES_192','AES_256')
AND db_id() > 4;



SELECT '7.2' as 'CIS Benchmark Ref', db_name() AS Database_Name, name AS Key_Name
FROM sys.asymmetric_keys
WHERE key_length < 2048
AND db_id() > 4;