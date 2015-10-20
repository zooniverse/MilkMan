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
    @results = Result.sort('metadata.occurrence_id').all(:group_id => params[:zoo_id])
    @metadata_keys = @results.first()[:metadata].keys
    @results.each do |result|
      result[:marks] = {}
      result[:reduced].each do |type, marks|
        marks.each do |mark|
          mark['labels'].each do |label|
            label.each do |k, v|
              max_vote = v.values.max
              result[:marks][k] = v.select { |k, vote| vote == max_vote }
            end
          end
        end
      end
    end
  end
  
  def csv

    results = Result.sort('metadata.occurrence_id').all(:group_id => params[:zoo_id])
    metadata_keys = results.first()[:metadata].keys

    column_names = ['Zooniverse ID', 'Classification count']
    column_names.concat metadata_keys
    column_names.concat ['Type', 'Value', 'Vote']
    
    results.each do |result|
      result[:marks] = {}
      result[:reduced].each do |type, marks|
        marks.each do |mark|
          mark['labels'].each do |label|
            label.each do |k, v|
              max_vote = v.values.max
              result[:marks][k] = v.select { |k, vote| vote == max_vote }
            end
          end
        end
      end
    end

    csv = CSV.generate do |csv|
      csv << column_names
      results.each do |result|
        result[:keywords].each do |type, votes|
          votes.each do |vote|
            row = [
              result[:subject_id],
              result[:classification_count]
            ]
            metadata_keys.each do |k|
              row << result[:metadata][k]
            end
            row.concat [
              type,
              vote[:choice],
              vote[:vote]
            ]
            csv << row
          end
        end
        result[:marks].each do |type,votes|
          votes.each do |choice, vote|
            row = [
              result[:subject_id],
              result[:classification_count]
            ]
            metadata_keys.each do |k|
              row << result[:metadata][k]
            end
            row.concat [
              type,
              choice,
              vote
            ]
            csv << row
          end
        end
      end
    end
    send_data csv, :filename => "#{params[:zoo_id]}.csv"
  end

end