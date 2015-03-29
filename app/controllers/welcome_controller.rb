
class WelcomeController < ApplicationController
  def index
    @pagetitle = Milkman::Application.config.project["name"]
    @eps = params[:eps] || Milkman::Application.config.project["dbscan"]["eps"]
    @min = params[:min] || Milkman::Application.config.project["dbscan"]["min"]
    @tutorial = Milkman::Application.config.project["tutorial_zoo_id"]
    @counts = Subject.counts

    # Load 12 illustrated subjects
    @illustrated_subject_ids = []
    subjects = Subject.where('metadata.has_illustrations_count' => {:$gte => 15}, :classification_count.lte => 25, :state => 'complete')
    subjects.limit(9).skip(rand(subjects.size-1)).each{|sr| @illustrated_subject_ids << sr.zooniverse_id }
    @illustrated_subject_ids = @illustrated_subject_ids.uniq
    
    # Load 12 most-recently cached subjects
    @recent_subject_ids = []
    scans = ScanResult.where(:zooniverse_id.ne => @tutorial, :eps => @eps.to_i, :min => @min.to_i).sort(:created_at.desc).limit(9)
    scans.each{|sr| @recent_subject_ids << sr.zooniverse_id }
    @recent_subject_ids = @recent_subject_ids.uniq

    # Load 9 controversial subjects
    @subject_ids = []
    subs = Subject.where(:classification_count.gte => 20, :state => 'complete')
    subs.limit(9).skip(rand(subs.size-1)).sort(:classification_count.desc).each{|sr| @subject_ids << sr.zooniverse_id }
    @subject_ids = @subject_ids.uniq

    # Preload more if there are not enough preloaded already
    if ScanResult.where(:zooniverse_id.ne => @tutorial, :eps => @eps.to_i, :min => @min.to_i).size < 18
      Subject.cache_results(n=3,@eps,@min)
    end
  end
end
