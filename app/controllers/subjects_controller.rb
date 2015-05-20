class SubjectsController < ApplicationController
  def index
    @pagetitle = Milkman::Application.config.project["name"]
    @state = params[:status]
    @page = params[:page].to_i
    subjects = Subject.fields(:zooniverse_id, :location).where(:state => @state)
    subjects = subjects.where('metadata.has_illustrations_count' => {:$gte => params[:has_illustrations].to_i}) if params[:has_illustrations]
    @g ||= subjects.paginate({:per_page => 20, :page => @page})
    @size = subjects.size
    num_pages = @size / 20
    num_pages = num_pages.ceil
    @first_page = [@page - 10, 1].max
    @last_page = [@first_page + 19, num_pages].min
  end

  def show
    @s ||= Subject.find_by_zooniverse_id(params[:zoo_id])
    @pagetitle = Milkman::Application.config.project["name"]
    
    @eps = params[:eps] || Milkman::Application.config.project["dbscan"]["eps"]
    @min = params[:min] || Milkman::Application.config.project["dbscan"]["min"]
    @results = @s.cache_scan_result(@eps,@min)
    
    @results.each do |k,v|
      v['reduced'].each do |mark|
        case k
        when 'flowering'
          votes = {}
          mark['labels'].each do |label|
            if label['flowering'] == nil
              keyword = 'blank'
            else
              keyword = label['flowering']
            end
            votes[keyword] ||= 0
            votes[keyword] += 1
          end
          votes = {'flowering' => votes}
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
        if a['value'].is_a?(Hash)
          a['value'].each do |k,v|
            if v.is_a?(String)
              votes[k] ||= {}
              votes[k][v] ||= 0
              votes[k][v] += 1
            end
          end
        else
          k = a['key']
          v = a['value']
          votes[k] ||= {}
          votes[k][v] ||= 0
          votes[k][v] += 1
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
