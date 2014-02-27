require 'rubygems'
require 'net/https'
require 'bundler'
Bundler.require

# This section sets up the goals database with a goals table
# OLD - DataMapper::setup(:default, "sqlite://#{Dir.pwd}/SBthree.db")
DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://localhost/ThreeOneOne")

class DailyCallData
  include DataMapper::Resource
  # property :id, Serial # 
  property :date, Date, :key => true # set date as the (primary) key
  property :avg_queue_time, Integer
  property :max_handle_time, Integer
  property :calls_handled_by_other, Integer
  property :avg_time_to_dequeue, Integer
  property :avg_time_toabandon, Integer
  property :max_abandon_per_day, Integer
  property :avg_abandon_per_day, Integer
  property :avg_handle_time, Integer
  property :day_of_week, Integer
  property :callsabandoned, Integer
  property :maxtime_todequeue, Integer
  property :abandoned_call, Integer
  property :callshandled, Integer
  property :avg_speedof_answer, Integer
  property :total_calls_handled, Integer
  property :callspresented, Integer
  property :max_queue_time, Integer 
  property :max_time_to_abandon, Integer 
  property :calls_dequeued, Integer 

  property :created_at, DateTime
  property :updated_at, DateTime
end

DataMapper.finalize.auto_upgrade!

# this code runs before the server is started
print "Fetching and parsing data from web service ... "
uri = URI('https://data.southbendin.gov/resource/contact-service-queue-activity.json?')

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER

request = Net::HTTP::Get.new(uri.request_uri)
request.add_field(ENV['SOCRATA_API_KEY'], ARGV[0])

response = http.request(request)
rows = JSON.parse(response.body)

print " ... \n"

##############################################

get "/" do
  @data = DailyCallData.all # get all the rows from the database
  
  @series_to_graph_allcall = [
    {:name => "Calls Handled", :data => DailyCallData.all.map{|i| [i.date.to_time.to_i*1000, i.total_calls_handled.to_i]}}
    ]

  @sum_total_calls = DataMapper.repository.adapter.select("SELECT SUM(callshandled) FROM daily_call_data").first
  @sum_calls_abandoned = DataMapper.repository.adapter.select("SELECT SUM(callsabandoned) FROM daily_call_data").first
  @sum_calls_deqeued = DataMapper.repository.adapter.select("SELECT SUM(calls_dequeued) FROM daily_call_data").first
  @avg_waittime = DataMapper.repository.adapter.select("SELECT avg(avg_queue_time) FROM daily_call_data").first.to_f.round(2)
  @avg_handletime = DataMapper.repository.adapter.select("SELECT avg(avg_handle_time) FROM daily_call_data").first.to_f.round(2)
  @avg_dequeuetime = DataMapper.repository.adapter.select("SELECT avg(calls_dequeued) FROM daily_call_data").first.to_f.round(2)
  @percent_abandoned = (@sum_calls_abandoned/@sum_total_calls.to_f).round(4)*100

	erb :index	
end

get "/dashboardcall" do

  all = DailyCallData.all
  @series_to_graph_call = [
    {:name => "Calls Handled", :data => all.map{|i| [i.date.to_time.to_i*1000, i.total_calls_handled.to_i]}},
    {:name => "Calls Presented", :data => all.map{|i| [i.date.to_time.to_i*1000, i.callspresented.to_i]}},
    {:name => "Calls Abandoned", :data => all.map{|i| [i.date.to_time.to_i*1000, i.callsabandoned.to_i]}},
    {:name => "Calls Handled By Others", :data => all.map{|i| [i.date.to_time.to_i*1000, i.calls_handled_by_other.to_i]}},
    {:name => "Max Abandoned", :data => all.map{|i| [i.date.to_time.to_i*1000, i.max_abandon_per_day.to_i]}},
    {:name => "Average Adandoned", :data => all.map{|i| [i.date.to_time.to_i*1000, i.avg_abandon_per_day.to_i]}},
    {:name => "Calls Deqeued", :data => all.map{|i| [i.date.to_time.to_i*1000, i.calls_dequeued.to_i]}}
  ]

	@series_to_graph_week = [
    {:name => "Calls Adandoned", :data => DataMapper.repository.adapter.select("SELECT to_char(date,'YYYY-WW') AS week_num,SUM(callsabandoned) AS sum_call_abandoned, to_char(date, 'YYYY-WW')AS week_text FROM daily_call_data GROUP by week_num, week_text ORDER BY week_text").map{|i| [i.week_text, i.sum_call_abandoned.to_i]}},
    {:name => "Total Calls", :data => DataMapper.repository.adapter.select("SELECT to_char(date,'YYYY-WW') AS week_num,SUM(callshandled) AS sum_call_handled, to_char(date, 'YYYY-WW')AS week_text FROM daily_call_data GROUP by week_num, week_text ORDER BY week_text").map{|i| [i.week_text, i.sum_call_handled.to_i]}}
    ]

  @series_to_graph_month = [
    {:name => "Total Calls", :data => DataMapper.repository.adapter.select("SELECT to_char(date, 'YYYY-MM') AS month_order_by, SUM(callshandled) AS sum_call_handled, to_char(date,  'Mon YYYY' ) AS month_text FROM daily_call_data GROUP by month_order_by, month_text ORDER BY month_order_by").map{|i| [i.month_text, i.sum_call_handled.to_i]}},
    {:name => "Calls Adandoned", :data => DataMapper.repository.adapter.select("SELECT to_char(date, 'YYYY-MM') AS month_order_by, SUM(callsabandoned) AS sum_call_abandoned, to_char(date,  'Mon YYYY' ) AS month_text FROM daily_call_data GROUP by month_order_by, month_text ORDER BY month_order_by").map{|i| [i.month_text, i.sum_call_abandoned.to_i]}}
    ]

  erb :dashboardcall
end

get "/dashboardtime" do

  all = DailyCallData.all
  @series_to_graph_time = [
    {:name => "Average Wait Time", :data => all.map{|i| [i.date.to_time.to_i*1000, i.avg_queue_time.to_i]}},
    {:name => "Average Time to Dequeue", :data => all.map{|i| [i.date.to_time.to_i*1000, i.avg_time_to_dequeue.to_i]}},
    {:name => "Average Time to Abandon", :data => all.map{|i| [i.date.to_time.to_i*1000, i.avg_time_toabandon.to_i]}},
    {:name => "Average Handle Time", :data => all.map{|i| [i.date.to_time.to_i*1000, i.avg_handle_time.to_i]}}
  ]

  @series_to_graph_time_week = [
    {:name => "Average Wait Time", :data => DataMapper.repository.adapter.select("SELECT to_char(date,'YYYY-WW') AS week_num,AVG(avg_queue_time) AS avg_avg_queue_time, to_char(date, 'YYYY-WW')AS week_text FROM daily_call_data GROUP by week_num, week_text ORDER BY week_text").map{|i| [i.week_text, i.avg_avg_queue_time.to_i]}},
    {:name => "Average Handle Time", :data => DataMapper.repository.adapter.select("SELECT to_char(date,'YYYY-WW') AS week_num,AVG(avg_handle_time) AS avg_avg_handle_time, to_char(date, 'YYYY-WW')AS week_text FROM daily_call_data GROUP by week_num, week_text ORDER BY week_text").map{|i| [i.week_text, i.avg_avg_handle_time.to_i]}}
    ]

    @series_to_graph_month = [
    {:name => "Average Wait Time", :data => DataMapper.repository.adapter.select("SELECT to_char(date, 'YYYY-MM') AS month_order_by, AVG(avg_queue_time) AS avg_avg_month_queue, to_char(date,  'Mon YYYY' ) AS month_text FROM daily_call_data GROUP by month_order_by, month_text ORDER BY month_order_by").map{|i| [i.month_text, i.avg_avg_month_queue.to_i]}},
    {:name => "Average Handle Time", :data => DataMapper.repository.adapter.select("SELECT to_char(date, 'YYYY-MM') AS month_order_by, AVG(avg_handle_time) AS avg_avg_month_handle_time, to_char(date,  'Mon YYYY' ) AS month_text FROM daily_call_data GROUP by month_order_by, month_text ORDER BY month_order_by").map{|i| [i.month_text, i.avg_avg_month_handle_time.to_i]}}
    ]

  erb :dashboardtime
end

get "/about" do
	erb :about
end
