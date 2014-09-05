
class ExploreController < ApplicationController
  def index
  	@pagetitle = Milkman::Application.config.project_name+": Data Explorer"
  	render :layout => "explore"
  end
end
