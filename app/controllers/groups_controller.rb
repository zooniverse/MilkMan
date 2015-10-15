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
    @g ||= Group.find_by_zooniverse_id(params[:zoo_id])
    @results ||= {}
    subjects = Subject.fields(:zooniverse_id, :metadata, :location).sort('metadata.occurrence_id').where('group.zooniverse_id' => params[:zoo_id], :classification_count => {:$gte => 5})
    
    subject_ids = []
    scan_results = {}

    subjects.each do |s|
      subject_ids << s.zooniverse_id
    end
    
    eps = Milkman::Application.config.project["dbscan"]["eps"]
    min = Milkman::Application.config.project["dbscan"]["min"]
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
      @metadata_keys ||= s['metadata'].keys
      @results[s.zooniverse_id] = {:keywords => s.keywords(), :reduced => reduced, :metadata => s['metadata']}
    end
  end

end