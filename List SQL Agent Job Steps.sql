use msdb

select
	@@ServerName as 'Server'
	,jobs.name as 'Job Name'
	--,case when jobs.[enabled] = 1 then 'Yes' else 'No' end as 'Job Enabled'
	--,SUSER_SNAME(jobs.owner_sid) as 'Job Owner'
	--,categories.name as 'Job Category'
	--,jobs.description as 'Job Description'

	,steps.step_id as 'Step Number'
	,steps.step_name as 'Step Name'
	,steps.subsystem as 'Step Type'
	,proxies.name as 'Run As'
	,steps.database_name as 'Database'
	,steps.command as 'Command'

	,case steps.on_success_action
        when 1 then 'Quit the job reporting success'
        when 2 then 'Quit the job reporting failure'
        when 3 then 'Go to the next step'
        when 4 then 'Go to Step: ' 
                    + quoteName(cast(steps.on_success_step_id as varchar(3))) 
                    + ' ' 
                    + onSuccess.step_name
     end as 'on Success'
    ,steps.retry_attempts as 'Retry Attempts'
    ,steps.retry_interval as 'Retry Interval (minutes)'
    ,case steps.on_fail_action
        when 1 then 'Quit the job reporting success'
        when 2 then 'Quit the job reporting failure'
        when 3 then 'Go to the next step'
        when 4 then 'Go to Step: ' 
                    + quoteName(cast(steps.on_fail_step_id as varchar(3))) 
                    + ' ' 
                    + onFailure.step_name
     end as 'on Failure'


	-- Add Last Run details
	,case steps.last_run_date
		when 0 then NULL
		else 
			cast(
				cast(steps.last_run_date as CHAR(8))
				+ ' ' 
				+ stuff(
					stuff(right('000000' + cast(steps.last_run_time as varchar(6)),  6)
						, 3, 0, ':')
					, 6, 0, ':')
				as datetime)
		end as 'Last Run Date/Time'
	,case steps.[last_run_outcome]
		when 0 then 'Failed'
		when 1 then 'Succeeded'
		when 2 then 'Retry'
		when 3 then 'Canceled'
		when 5 then 'Unknown'
		end as 'Last Run Status'
	,stuff(
			stuff(right('000000' + cast(steps.last_run_duration as varchar(6)),  6)
				, 3, 0, ':')
			, 6, 0, ':')
		as 'Last Run Duration (hh:mm:ss)'
	,steps.last_run_retries as 'Last Run Retries'

from
	sysjobsteps as steps
	inner join sysjobs as jobs on steps.job_id = jobs.job_id
	left join sysjobsteps as onSuccess on steps.job_id = onSuccess.job_id and steps.on_success_step_id = onSuccess.step_id
	left join sysjobsteps as onFailure on steps.job_id = onFailure.job_id and steps.on_fail_step_id = onFailure.step_id
	left join sysproxies as proxies on steps.proxy_id = proxies.proxy_id
	left join syscategories as categories on categories.category_id = jobs.category_id
order by jobs.name, steps.step_id
