SELECT '2.1' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'ad hoc distributed queries';
UNION
SELECT '2.2' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'clr enabled'; 
UNION
SELECT '2.3' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Cross db ownership chaining';
UNION
SELECT '2.4' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Database Mail XPs';
UNION
SELECT '2.5' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Ole Automation Procedures';
UNION
SELECT '2.6' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Remote access';
UNION
SELECT '2.7' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Remote admin connections' AND SERVERPROPERTY('IsClustered') = 0;
UNION
SELECT '2.8' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Scan for startup procs';
UNION
SELECT '2.9' as 'CIS Benchmark Ref', name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name != 'msdb' AND state = 0; 
