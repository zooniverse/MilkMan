class SubjectsController < ApplicationController
  def index
  end

  def show
    @s ||= Subject.find_by_zooniverse_id(params[:zoo_id])
    @pagetitle = Milkman::Application.config.project["name"]
    
    @eps = params[:eps] || Milkman::Application.config.project["dbscan"]["eps"]
    @min = params[:min] || Milkman::Application.config.project["dbscan"]["min"]
    @results = @s.cache_scan_result(@eps,@min)
    
    @results.each do |k,v|
      puts v
      v['reduced'].each do |mark|
        case k
        when 'drawing', 'chart', 'map', 'photograph'
          votes = {}
          mark['labels'].each do |label|
            if label['details'] == nil
              keywords = []
            else
              keywords = label['details']['keywords'].split(/[;,]\s*/)
            end
            keywords.each do |keyword|
              votes[keyword] ||= 0
              votes[keyword] += 1
            end
          end
          votes = {'keywords' => votes}
          mark['labels'] = [votes]
        when 'species'
          votes = self.gather_votes(['common', 'scientific'], mark['labels'], 'subject')
          mark['labels'] = [votes]
        when 'contributor'
          name_votes = self.gather_votes(['name'], mark['labels'], 'name')
          role_votes = self.gather_votes(['role'], mark['labels'], 'role')
          mark['labels'] = [name_votes, role_votes]
        when 'inscription'
          votes = self.gather_votes(['text'], mark['labels'], 'inscription')
          mark['labels'] = [votes]
        end
      end
      
      votes = {}
      @s.annotations.each do |a|
        if a.is_a?(String)
          keywords = a.split(/[;,]\s*/)
          keywords.each do |k|
            votes[k] ||= 0
            votes[k] += 1
          end
        end
      end
      @keywords = votes
    end

    render "subjects/show"
  end
  
  def page
    @s = Subject.first('metadata.page_id' => params[:page_id])
    self.show()
  end

  def preview
    @s = Subject.find_by_zooniverse_id(params[:zoo_id])
    @eps = params[:eps]
    @min = params[:min]
    @results = @s.cache_scan_result(@eps,@min)
    render :layout => false
  end

  def coordinates
    @pagetitle = Milkman::Application.config.project["name"]
    @subjects = Subject.find_in_range(params[:lon].to_f, params[:lat].to_f)
  end

  def raw
    @s = Subject.find_by_zooniverse_id(params[:zoo_id])
    @eps = params[:eps] || Milkman::Application.config.project["dbscan"]["eps"]
    @min = params[:min] || Milkman::Application.config.project["dbscan"]["min"]
    begin
    @raw = ScanResult.first(:zooniverse_id => @s.zooniverse_id, :eps => @eps.to_i, :min => @min.to_i).annotations
    rescue
      @raw = {}
    end
    render :layout => false
  end
  
  def gather_votes(fields, set, key)
    votes = {}
    set.each do |t|
      fields.each do |f|
        votes[f] ||= {}
        if t[key] == nil
          label = 'blank'
        else
          label = t[key][f]
        end
        # label = 'none' if label == ''
        votes[ f ][ label ] ||= 0
        votes[ f ][ label ] += 1
      end
    end
    votes
  end

end
