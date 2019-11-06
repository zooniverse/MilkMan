class GroupsController < ApplicationController
  
  def index
    @groups = Group.all
    @pagetitle = Milkman::Application.config.project["name"]
  end
  
  def show
    @page = params[:page].to_i
    @pagetitle = Milkman::Application.config.project["name"]
  	@g ||= Group.find_by_zooniverse_id(params[:zoo_id])
    num_pages = @g.illustrated_pages / 20
    num_pages = num_pages.ceil
    @first_page = [@page - 10, 1].max
    @last_page = [@first_page + 19, num_pages].min
  end
  
  def export
    @g = Group.find_by_zooniverse_id(params[:zoo_id])
    
    @results ||= self.gather_results params[:zoo_id]
  end

  def subjects
    @g = Group.find_by_zooniverse_id(params[:zoo_id])
    @subjects = Subject.where('metadata.has_illustrations_count' => {:$gte => 3}, 'group.zooniverse_id' => params[:zoo_id]).fields(:zooniverse_id, :metadata)
  end

  def csv
    @g = Group.find_by_zooniverse_id(params[:zoo_id])
    
    @results ||= self.gather_results params[:zoo_id]
    
    column_names = [
      'Zooniverse ID',
      'Classification count',
      'Page ID',
      'Volume',
      'Page',
      'Year',
      'Image scale',
      'Type',
      'Coords',
      'Value'
    ]
    
    csv = CSV.generate do |csv|
      csv << column_names
      @results.each do |result|
        csv << [
          result[:subject_id],
          result[:classification_count],
          result[:page_id],
          result[:volume],
          result[:page],
          result[:year],
          result[:scale],
          'Page keywords',
          [],
          result[:keywords]
        ]
        result[:reduced].each do |mark|
          csv << [
            result[:subject_id],
            result[:classification_count],
            result[:page_id],
            result[:volume],
            result[:page],
            result[:year],
            result[:scale],
            mark["type"],
            mark["coords"],
            mark["value"]
          ]
        end
      end
    end
    
    send_data csv, :filename => "#{params[:zoo_id]}.csv"
  end
  
  def gather_results(zoo_id)
    Result.sort(:page_id).all(:group_id => zoo_id)
  end

end