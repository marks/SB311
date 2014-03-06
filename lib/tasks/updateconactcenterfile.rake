# this code runs before the server is started
task :loaddatabase do 	
	print "Fetching and parsing aggregate call data from web service ... "
	uri = URI('https://data.southbendin.gov/resource/contact-service-queue-activity.json?')

	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_PEER

	request = Net::HTTP::Get.new(uri.request_uri)
	request.add_field(ENV['SOCRATA_API_KEY'], ARGV[0])

	response = http.request(request)
	rows = JSON.parse(response.body)

	print " ... \n"

	rows.each do |row_data|
	  print "Processing row where date=#{row_data["date"]} ..."
	  db_row = DailyCallData.get(:date => row_data["date"])
	  begin 
	    if DailyCallData.create(row_data)
	      print " ... inserted it int the DB\n"
	    else
	      print " ... ERROR WHILE INSERTING INTO DB"
	    end
	  rescue DataObjects::IntegrityError
	    # do nothing, you already have a record for that date.. but you might want to update it if the data changes after the fact
	    print " ... already had that date in the DB\n"
	  end
	end
	puts "There are #{DailyCallData.count} rows in the database"
end

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
