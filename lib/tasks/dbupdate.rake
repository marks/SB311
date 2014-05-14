# this code runs before the server is started
task :loaddatabase do 	
	print "Fetching and parsing aggregate call data from web service ... "
	uri = URI('http://data.southbendin.gov/resource/contact-service-queue-activity.json?')

	http = Net::HTTP.new(uri.host, uri.port)

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
	      print " ... inserted it into the DB\n"
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
