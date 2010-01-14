require 'app'
require 'google_analytics'

#http://www.nickhammond.com/2009/03/28/easy-logging-with-sinatra/
log = File.new("log/sinatra.log", "a+")
$stdout.reopen(log)
$stderr.reopen(log)

use Rack::GoogleAnalytics,ENV['GA_ID']
run TwitterListManager
