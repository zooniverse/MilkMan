class GroupsController < ApplicationController
  
  def index
    @groups = Group.all
    @pagetitle = Milkman::Application.config.project["name"]
  end
  
  def show
    @page = params[:page].to_i
    @pagetitle = Milkman::Application.config.project["name"]
  	@g ||= Group.find_by_zooniverse_id(params[:zoo_id])
    num_pages = @g.stats['total'].to_f / 20
    num_pages = num_pages.ceil
    @first_page = [@page - 10, 1].max
    @last_page = [@first_page + 19, num_pages].min
  end
  
  def export
    @g = Group.find_by_zooniverse_id(params[:zoo_id])
    
    @results ||= {}
    
    Subject.fields(:zooniverse_id, :location).sort('metadata.page_id').find_each('group.zooniverse_id' => params[:zoo_id], 'metadata.has_illustrations_count' => {:$gte => 5}) do |s|
      eps = params[:eps] || Milkman::Application.config.project["dbscan"]["eps"]
      min = params[:min] || Milkman::Application.config.project["dbscan"]["min"]
      result = s.process_labels(s.cache_scan_result(eps,min))
      reduced = {}
      result.each do |type, res|
        reduced[type] = res['reduced'] unless res['reduced'] == []
      end
      @results[s.zooniverse_id] = {:keywords => s.keywords(), :reduced => reduced}
    end
  end


end