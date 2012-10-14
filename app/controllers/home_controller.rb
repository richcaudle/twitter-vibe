class HomeController < ApplicationController
  def index
  	@app_key = Pusher.key
  end

  def test
  	@app_key = Pusher.key
  end

  def hide

	if !(params[:term].nil?)
  		
  		db_term = Term.find_by_name(params[:term].downcase)
  		db_term.hide = true
  		db_term.save

    	@notice = 'Hide completed!'
    	
  	end
  end

end
