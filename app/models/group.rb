class Group
  include MongoMapper::Document
  set_collection_name "#{Milkman::Application.config.project["slug"]}_groups"
  
  key :zooniverse_id, String
  key :stats, Hash
  key :metadata, Hash
  
  def start_date
    Time.at self.metadata["start_date"]
  end
  
  def end_date
    Time.at self.metadata["end_date"]
  end
  
  def pages( page = 0 )
    @pages ||= []
    offset = (page - 1) * 20
    if @pages.empty?
      Subject.where('metadata.has_illustrations_count' => {:$gte => 3}, 'group.zooniverse_id' => self.zooniverse_id).fields(:zooniverse_id, :location).sort('metadata.page_id').limit(20).skip( offset ).find_each do |g|
        @pages << g
      end
    end
    @pages
  end

  def illustrated_pages
    subjects = Subject.where('metadata.has_illustrations_count' => {:$gte => 3}, 'group.zooniverse_id' => self.zooniverse_id)
    subjects.size
  end

  def completed
    completed = 100 * self.stats['complete'].to_f/self.stats['total'].to_f
    completed.round unless self.stats['total'].to_i == 0
  end
  
  def classifications_per_page
    cpp = self.classification_count.to_f / self.stats['total'].to_f
    cpp.round 1
  end
end