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
      @results.each do |result|
        csv << [
          result[:subject_id],
          result[:classification_count],
          result[:page_id],
          'Page keywords',
          [],
          result[:keywords]
        ]
        result[:reduced].each do |mark|
          csv << [
            result[:subject_id],
            result[:classification_count],
            result[:page_id],
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
    Result.all(:group_id => zoo_id)
  end

end