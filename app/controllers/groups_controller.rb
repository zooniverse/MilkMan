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
    
    @results ||= self.gather_results params[:zoo_id]
  end
  
  def csv
    @g = Group.find_by_zooniverse_id(params[:zoo_id])
    
    @results ||= self.gather_results params[:zoo_id]
    
    column_names = [
      'Zooniverse ID',
      'Classification count',
      'Page ID',
      'Type',
      'Coords',
      'Value'
    ]
    
    csv = CSV.generate do |csv|
      csv << column_names
      @results.each do |zoo_id, result|
        csv << [
          zoo_id,
          result[:classification_count],
          result[:page_id],
          'Page keywords',
          [],
          result[:keywords]
        ]
        result[:reduced].each do |type, res|
          res.each do |a|
            coords = [ a['x'].to_i, a['y'].to_i, a['left'].to_i, a['top'].to_i, a['width'].to_i, a['height'].to_i ]
            value = {}
            a['labels'].each do |label|
              label.each do |k,v|
                value[k] = v.keys
              end
            end
            csv << [
              zoo_id,
              result[:classification_count],
              result[:page_id],
              type,
              coords,
              value
            ]
          end
        end
      end
    end
    
    send_data csv, :filename => "#{params[:zoo_id]}.csv"
  end
  
  def gather_results(zoo_id)
    
    results = {}
    subject_ids = []
    scan_results = {}
    keywords = {}
    
    Result.fields(:subject_id, :keywords).where(:group_id => zoo_id).each do |r|
      keywords[r.subject_id] = r.keywords
    end
    
    subjects = Subject.fields(:zooniverse_id, :metadata, :classification_count).sort('metadata.page_id').where('group.zooniverse_id' => zoo_id, 'metadata.has_illustrations_count' => {:$gte => 5})
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
      # keywords = {}
      results[s.zooniverse_id] = {:classification_count => s.classification_count, :page_id => s.metadata['page_id'], :keywords => keywords[s.zooniverse_id], :reduced => reduced}
    end
    
    results
  end


end