task: loaddatabase do 	
	rows.each do |row_data|
	  print "Processing row where date=#{row_data["date"]} ..."
	  db_row = DailyCallData.get(:date => row_data["date"])#.first
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