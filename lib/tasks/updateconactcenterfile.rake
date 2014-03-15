# this code runs before the server is started
task :getcontactcenterfile do
print "Dowloading file ...."
result = JSON.parse open('https://data.southbendin.gov/api/views/aiua-8jdv/rows.json?accessType=DOWNLOAD').read

	result["data"].each do |result_data|
		# puts result_data.inspect # array from JSON data
		call_data = {
			:call_id => result_data[8].to_i,
			:call_type_code => result_data[13].to_i,
			:entry_year => result_data[16].to_i,
			:entry_month => result_data[17].to_i,
			:call_status => result_data[15].to_i,
			:entry_date_calc => result_data[9],
			:close_date_calc => result_data[10],
			:work_group_define => result_data[11],
			:work_group_description => result_data[12],
			:call_type_description => result_data[14],
		}
		# puts call_data.inspect # hash created from said array
		print "Processing row where call_id=#{call_data[:call_id]} ..."
		db_row = ContactCallData.get(:call_id => call_data[:call_id])
		begin 
	    if ContactCallData.create(call_data)
	      print " ... inserted it int the DB\n"
	    else
	      print " ... ERROR WHILE INSERTING INTO DB"
	    end
	  rescue DataObjects::IntegrityError
	    # do nothing, you already have a record for that date.. but you might want to update it if the data changes after the fact
	    print " ... already had that call id in the DB\n"
		end
	end
	puts "There are #{ContactCallData.count} rows in the database"
end
