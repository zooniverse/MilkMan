class ResultsController < ApplicationController

  def random
    results = Result.where('reduced.type' => params[:type])
    results_count = results.size
    result = results.limit(1).skip(rand(results_count - 1)).first()
    @subject = Subject.where(:zooniverse_id => result.subject_id).first()
    @illustrations = result.marks params[:type]
    @species = result.marks 'species'
    @contributors = result.marks 'contributor'
    @keywords = result.keywords
  end

end