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
    subject_ids = []
    scan_results = {}
    
    subjects = Subject.fields(:zooniverse_id).sort('metadata.page_id').where('group.zooniverse_id' => params[:zoo_id], 'metadata.has_illustrations_count' => {:$gte => 5}).limit(100)
    subjects.each do |s|
      subject_ids << s.zooniverse_id
    end
    
    eps = params[:eps] || Milkman::Application.config.project["dbscan"]["eps"]
    min = params[:min] || Milkman::Application.config.project["dbscan"]["min"]
    ScanResult.find_each(:zooniverse_id => {:$in => subject_ids}, :eps => eps.to_i, :min => min.to_i) do |s|
      scan_results[s.zooniverse_id] = s.annotations
    end
    
    subjects.each do |s|
      scan_result = scan_results[s.zooniverse_id]
      result = s.process_labels scan_result
      reduced = {}
      result.each do |type, res|
        reduced[type] = res['reduced'] unless res['reduced'] == []
      end
      # keywords = {}
      keywords = s.keywords()
      @results[s.zooniverse_id] = {:keywords => keywords, :reduced => reduced}
    end
  end


end