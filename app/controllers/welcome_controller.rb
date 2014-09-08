
class WelcomeController < ApplicationController
  def index
    @pagetitle = Milkman::Application.config.project["name"]

    # Load 12 most-recently cached subjects
    @subjects = []
    @subjects = ScanResult.where(:zooniverse_id.ne => "AMW0000v75").sort(:created_at.desc).limit(12)

    # Preload 10 more if there are less than 100 preloaded already
    if ScanResult.where(:zooniverse_id.ne => "AMW0000v75").size < 18
      Subject.cache_results(n=3)
    end
  end
end
