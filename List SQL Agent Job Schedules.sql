use msdb

select	 
		@@ServerName as 'Server'
		,jobs.name  as 'Job Name'
		--,case jobs.enabled when 1 then 'Yes' else 'No' end as 'Job Enabled'
		--,case schedule.enabled when 1 then 'Yes' else 'No' end as 'Scheduled'
		--,SUSER_SNAME(jobs.owner_sid) as 'Owner'
		--,categories.name as 'Job Category'
		--,jobs.description as 'Job Description'
		,case when schedule.name is null then '' else schedule.name end as 'Schedule Name'
		,case 
			when schedule.[enabled] = 1 then 'Yes'
			when schedule.name is not null and schedule.[enabled] = 0 then 'No'
			else '' end as 'Schedule Enabled'
		,case schedule.freq_type
			when   1 then 'Once'
			when   4 then 'Daily'
			when   8 then 'Weekly'
			when  16 then 'Monthly'
			when  32 then 'Monthly'
			when  64 then 'When SQL Server Agent starts'
			when 128 then 'When the CPU(s) become idle' 
			else ''
		 end as 'Frequency'
		,case schedule.freq_type
			when   1 then '' -- One time only
			when   4 then 
				case when schedule.freq_interval <> 1 then 'Every ' + convert(varchar, schedule.freq_interval) + 'days' else '' end
						
			when   8 then 
				case when schedule.freq_recurrence_factor > 1 then 'Every ' + convert(varchar, schedule.freq_recurrence_factor) + ' weeks on ' else 'On ' end 
				+
				left(
					case when schedule.freq_interval &  1 =  1 then 'Sunday, '    else '' end + 
					case when schedule.freq_interval &  2 =  2 then 'Monday, '    else '' end + 
					case when schedule.freq_interval &  4 =  4 then 'Tuesday, '   else '' end + 
					case when schedule.freq_interval &  8 =  8 then 'Wednesday, ' else '' end + 
					case when schedule.freq_interval & 16 = 16 then 'Thursday, '  else '' end + 
					case when schedule.freq_interval & 32 = 32 then 'Friday, '    else '' end + 
					case when schedule.freq_interval & 64 = 64 then 'Saturday, '  else '' end , 
					len(
						case when schedule.freq_interval &  1 =  1 then 'Sunday, '    else '' end + 
						case when schedule.freq_interval &  2 =  2 then 'Monday, '    else '' end + 
						case when schedule.freq_interval &  4 =  4 then 'Tuesday, '   else '' end + 
						case when schedule.freq_interval &  8 =  8 then 'Wednesday, ' else '' end + 
						case when schedule.freq_interval & 16 = 16 then 'Thursday, '  else '' end + 
						case when schedule.freq_interval & 32 = 32 then 'Friday, '    else '' end + 
						case when schedule.freq_interval & 64 = 64 then 'Saturday, '  else '' end 
					) - 1
				)
			when  16 then 
				'On day ' + convert(varchar, schedule.freq_interval) + 
				+ case when schedule.freq_recurrence_factor <> 1 then (' of every ' + convert(varchar, schedule.freq_recurrence_factor) + ' months') else ' of each month' end

			when  32 then 
					'On ' + 
					case schedule.freq_relative_interval
						when  1 then '1st'
						when  2 then '2nd'
						when  4 then '3rd'
						when  8 then '4th'
						when 16 then 'last' 
					end +
					case schedule.freq_interval
						when  1 then ' Sunday'
						when  2 then ' Monday'
						when  3 then ' Tuesday'
						when  4 then ' Wednesday'
						when  5 then ' Thursday'
						when  6 then ' Friday'
						when  7 then ' Saturday'
						when  8 then ' day'
						when  9 then ' weekday'
						when 10 then ' weekend day' 
					end + 
					+ case when schedule.freq_recurrence_factor <> 1 then (' of every ' + convert(varchar, schedule.freq_recurrence_factor) + ' months') else ' of each month' end
			else ''
		 end as 'Frequency Details'
		,case schedule.freq_subday_type
			when 1 then stuff(stuff(right('000000' + convert(varchar(8), schedule.active_start_time), 6), 5, 0, ':'), 3, 0, ':')
			when 2 then 'Every ' + 
						case when schedule.freq_subday_interval > 1 then convert(varchar, schedule.freq_subday_interval) + ' seconds' else 'second' end
						+ ' between ' + 
						stuff(stuff(right('000000' + convert(varchar(8), schedule.active_start_time), 6), 5, 0, ':'), 3, 0, ':') + ' and ' + 
						stuff(stuff(right('000000' + convert(varchar(8), schedule.active_end_time), 6), 5, 0, ':'), 3, 0, ':')
			when 4 then 'Every ' + 
						case when schedule.freq_subday_interval > 1 then convert(varchar, schedule.freq_subday_interval) + ' minutes' else 'minute' end
						+ ' between ' + 
						stuff(stuff(right('000000' + convert(varchar(8), schedule.active_start_time), 6), 5, 0, ':'), 3, 0, ':') + ' and ' + 
						stuff(stuff(right('000000' + convert(varchar(8), schedule.active_end_time), 6), 5, 0, ':'), 3, 0, ':')
			when 8 then 'Every ' + 
						case when schedule.freq_subday_interval > 1 then convert(varchar, schedule.freq_subday_interval) + ' hours' else 'hour' end
						+ ' between ' + 
						stuff(stuff(right('000000' + convert(varchar(8), schedule.active_start_time), 6), 5, 0, ':'), 3, 0, ':') + ' and ' + 
						stuff(stuff(right('000000' + convert(varchar(8), schedule.active_end_time), 6), 5, 0, ':'), 3, 0, ':')
			else ''
		 end as 'Time Of Day'

from	 sysjobs as jobs with(nolock) 
		 left outer join sysjobschedules as jobschedule with(nolock) on jobs.job_id = jobschedule.job_id 
		 left outer join sysschedules as schedule with(nolock) on jobschedule.schedule_id = schedule.schedule_id 
		 inner join syscategories categories with(nolock) on jobs.category_id = categories.category_id 

order by jobs.name, schedule.freq_type, schedule.name 
