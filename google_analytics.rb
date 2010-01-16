# By Sam Pohlenz
#http://gist.github.com/276691
module Rack
  class GoogleAnalytics
    TRACKING_CODE = <<-EOCODE
<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
try {
var pageTracker = _gat._getTracker("{{ID}}");
pageTracker._trackPageview();
} catch(err) {}</script>
EOCODE
    
    def initialize(app, id)
      @app = app
      @id = id
    end
    
    def call(env)
      status, headers, body = @app.call(env)
      
      body.each do |part|
        if part =~ /<\/body>/
          part.sub!(/<\/body>/, "#{tracking_code}</body>")
 
          if headers['Content-Length']
            headers['Content-Length'] = (headers['Content-Length'].to_i + tracking_code.length).to_s
          end
 
          break
        end
      end
      
      [status, headers, body]
    end
  
  private
    def tracking_code
      TRACKING_CODE.sub(/\{\{ID\}\}/, @id)
    end
  end
end
 
