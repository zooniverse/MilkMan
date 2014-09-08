class Classification
  include MongoMapper::Document
  belongs_to :subject
  set_collection_name "#{Milkman::Application.config.project["slug"]}_classifications"

  key :project_id, ObjectId
  key :workflow_id, ObjectId
  key :user_id, ObjectId, :optional
  key :user_name, String, :optional
  key :annotations, Array
  key :subject_ids, Array
  key :zooniverse_id, String

  scope :for_subject, lambda {|zid| where(:subject_ids => [Subject.find_by_zooniverse_id(zid).id]) }

  def self.most_recent
      Classification.sort(:created_at.desc).first
  end

  def subject
    Subject.find(subject_ids.first)
  end

  def subject_id
    subject_ids.first
  end

end
