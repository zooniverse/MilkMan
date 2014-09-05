class SubjectsController < ApplicationController
  def index
  end

  def show
    @s = Subject.find_by_zooniverse_id(params[:zoo_id])
    @pagetitle = Milkman::Application.config.project_name
    
    if @s.dr1 == true
      @results = CatalogueObject.where(:glon => {:$gt => @s.glon-(@s.width/2.0), :$lt => @s.glon+(@s.width/2.0)}, :glat => {:$gt => @s.glat-(@s.height/2.0), :$lt => @s.glat+(@s.height/2.0)})
      render "subjects/show_dr1"
    else
      @results = @s.cache_scan_result
      render "subjects/show"
    end
  end

  def preview
    width = 400
    height = 200
    @s = Subject.find_by_zooniverse_id(params[:zoo_id])
    @results = @s.cache_scan_result
    render :layout => false
  end

  def coordinates
    @pagetitle = "Milkman"
    @subjects = Subject.find_in_range(params[:lon].to_f, params[:lat].to_f)
  end

  def simbad
    @s = Subject.find_by_zooniverse_id(params[:zoo_id])
    @pagetitle = "Milkman"
    @simbad = @s.simbad_for_svg
    # puts @simbad
    render :layout => false
  end

  def raw
    @s = Subject.find_by_zooniverse_id(params[:zoo_id])
    @raw = @s.annotations
    @pagetitle = "Milkman"
    render :layout => false
  end

end
