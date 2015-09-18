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
    keywords = {}
    
    Result.fields(:subject_id, :keywords).where(:group_id => params[:zoo_id]).each do |r|
      keywords[r.subject_id] = r.keywords
    end
    
    subjects = Subject.fields(:zooniverse_id, :metadata, :classification_count).sort('metadata.page_id').where('group.zooniverse_id' => params[:zoo_id], 'metadata.has_illustrations_count' => {:$gte => 5})
    subjects.each do |s|
      subject_ids << s.zooniverse_id
    end
    
    eps = params[:eps] || Milkman::Application.config.project["dbscan"]["eps"]
    min = params[:min] || Milkman::Application.config.project["dbscan"]["min"]
    ScanResult.find_each(:zooniverse_id => {:$in => subject_ids}, :eps => eps.to_i, :min => min.to_i) do |s|
      scan_results[s.zooniverse_id] = s.annotations
    end
    
    subjects.each do |s|
      scan_result = scan_results[s.zooniverse_id] || s.cache_scan_result(eps, min)
      result = s.process_labels scan_result
      reduced = {}
      result.each do |type, res|
        reduced[type] = res['reduced'] unless res['reduced'] == []
      end
      # keywords = {}
      @results[s.zooniverse_id] = {:classification_count => s.classification_count, :page_id => s.metadata['page_id'], :keywords => keywords[s.zooniverse_id], :reduced => reduced}
    end
  end


end