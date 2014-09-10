class SubjectsController < ApplicationController
  def index
  end

  def show
    @s = Subject.find_by_zooniverse_id(params[:zoo_id])
    @pagetitle = Milkman::Application.config.project["name"]
    
    eps = params[:eps] || Milkman::Application.config.project["dbscan"]["eps"]
    min = params[:min] || Milkman::Application.config.project["dbscan"]["min"]
    @results = @s.cache_scan_result(eps,min)

    render "subjects/show"
  end

  def preview
    width = 400
    height = 200
    @s = Subject.find_by_zooniverse_id(params[:zoo_id])
    eps = params[:eps] || Milkman::Application.config.project["dbscan"]["eps"]
    min = params[:min] || Milkman::Application.config.project["dbscan"]["min"]
    @results = @s.cache_scan_result(eps,min)
    render :layout => false
  end

  def coordinates
    @pagetitle = Milkman::Application.config.project["name"]
    @subjects = Subject.find_in_range(params[:lon].to_f, params[:lat].to_f)
  end

  def raw
    @s = Subject.find_by_zooniverse_id(params[:zoo_id])
    begin
      @raw = ScanResult.find_by_zooniverse_id(@s.zooniverse_id)
    rescue
      @raw = {}
    end
    @pagetitle = Milkman::Application.config.project["name"]
    render :layout => false
  end

end
