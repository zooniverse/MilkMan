class GroupsController < ApplicationController
  
  def index
    @groups = Group.all
    @pagetitle = Milkman::Application.config.project["name"]
  end
  
  def show
    @page = params[:page].to_i
    @pagetitle = Milkman::Application.config.project["name"]
  	@g ||= Group.find_by_zooniverse_id(params[:zoo_id])
    @num_pages = @g.stats['total'].to_f / 20
    @num_pages = @num_pages.ceil
    @next_page = @page + 1
    @prev_page = @page - 1
  end


end