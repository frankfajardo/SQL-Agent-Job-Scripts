use msdb

if object_id('tempdb..#mostRecentRunOfEachJob') is not null
	drop table #mostRecentRunOfEachJob

select * 
into #mostRecentRunOfEachJob
from sysjobhistory 
where step_id = 0 
  and (convert(nvarchar(50), job_id) + ' ' + convert(nvarchar(20), run_date) + ' ' + right('000000' + convert(nvarchar(6), run_time), 6)) in 
	(select convert(nvarchar(50), job_id) + ' ' + max(convert(nvarchar(20), run_date) + ' ' + right('000000' + convert(nvarchar(6), run_time), 6))
	from sysjobhistory 
	where step_id = 0 
	group by job_id)

select
	@@ServerName as 'Server'
	,jobs.name as 'Job Name'
	,case when jobs.[enabled] = 1 then 'Yes' else 'No' end as 'Job Enabled'
	,(select case count(*) when 0 then 'None' else convert(varchar, count(*)) end from sysjobsteps as steps where steps.job_id = jobs.job_id) as 'Steps'
	,(select case count(*) when 0 then 'None' else convert(varchar, count(*)) end from sysjobschedules as js 
		left outer join sysschedules as sched on js.schedule_id = sched.schedule_id 
		where js.job_id = jobs.job_id) as 'Schedules'
	,(select case count(*) when 0 then 'None' else convert(varchar, count(*)) end from sysjobschedules as js 
		left outer join sysschedules as sched on js.schedule_id = sched.schedule_id 
		where sched.enabled = 1	and js.job_id = jobs.job_id ) as 'Enabled Schedules'
	,SUSER_SNAME(jobs.owner_sid) as 'Job Owner'
	,case categories.name when '[Uncategorized (Local)]' then '' else categories.name end as 'Job Category'
	,case jobs.description when 'No description available.' then '' else jobs.description end as 'Job Description'
	,case jobs.notify_level_email 
		when 0 then '' -- Never / None
		when 1 then 'On Success'
		when 2 then 'On Failure'
		when 3 then 'On Completion (Success or Fail)'
	 end as 'Email Notify Level'
	,case 
		when jobs.notify_email_operator_id = 0 then '' 
		when operators.enabled = 0 then '(Disabled) ' + operators.email_address 
		else operators.email_address end as 'Email to Notify'

	,jobs.date_created as 'Created on'
	,jobs.date_modified as 'Last Modified on'

	,case
		when jh.run_date = 0 then 'No info' 
		when jh.run_date is null then 'No info'
		else 
			stuff(stuff(cast(jh.run_date as char(8)), 5, 0, '/'), 8, 0, '/')
			+ ' ' 
			+ stuff(stuff(right('000000' + cast(jh.run_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
	 end as 'Last Run Date/Time'

	,case 
		when jh.run_duration is null then ''
		else
			stuff(stuff(right('000000' + cast(jh.run_duration as varchar(6)),  6), 3, 0, ':'), 6, 0, ':') 
	 end as 'Last Run Duration (hh:mm:ss)'

	,case 
		when jh.run_status is null then ''
		when jh.run_status = 0 then 'Failed'
		when jh.run_status = 1 then 'Succeded' 
		when jh.run_status = 2 then 'Retry' 
		when jh.run_status = 3 then 'Cancelled' 
		when jh.run_status = 4 then 'In Progress' 
	 end as 'Last Run Status'

	,case 
		when jh.message is null then ''
		else jh.message 
	 end as 'Last Run Message'

from
	sysjobs as jobs 
	left join syscategories as categories on categories.category_id = jobs.category_id
	left join sysoperators as operators on jobs.notify_email_operator_id = operators.id
	left join #mostRecentRunOfEachJob as jh on jh.job_id = jobs.job_id

order by jobs.name
