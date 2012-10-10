class HomeController < ApplicationController
  def index
  	@app_key = Pusher.key
  end
end
