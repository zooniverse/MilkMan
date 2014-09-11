
class WelcomeController < ApplicationController
  def index
    @pagetitle = Milkman::Application.config.project["name"]

    # Load 12 most-recently cached subjects
    @subject_ids = []
    @eps = params[:eps] || Milkman::Application.config.project["dbscan"]["eps"]
    @min = params[:min] || Milkman::Application.config.project["dbscan"]["min"]
    scans = ScanResult.where(:zooniverse_id.ne => Milkman::Application.config.project["tutorial_zoo_id"], :eps => @eps.to_i, :min => @min.to_i).sort(:created_at.desc).limit(12)
    scans.each{|sr| @subject_ids << sr.zooniverse_id }
    @subject_ids = @subject_ids.uniq

    # Preload more if there are not enough preloaded already
    if ScanResult.where(:zooniverse_id.ne => Milkman::Application.config.project["tutorial_zoo_id"], :eps => @eps.to_i, :min => @min.to_i).size < 18
      Subject.cache_results(n=3,@eps,@min)
    end
  end
end
