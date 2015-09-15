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
    @results = @s.process_labels @s.cache_scan_result(@eps,@min)

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

end
