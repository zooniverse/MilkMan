require 'open-uri'
require 'json'
require 'fastimage'

class Hash
  def dig(*path)
    path.inject(self) do |location, key|
      location.respond_to?(:keys) ? location[key] : nil
    end
  end
end

class Subject
  include MongoMapper::Document
  include ApplicationHelper
  # many :classifications
  set_collection_name "#{Milkman::Application.config.project["slug"]}_subjects"

  key :project_id, ObjectId
  key :workflow_ids, Array
  key :zooniverse_id, String
  key :state, String

  key :location, Hash
  key :classification_count, Integer
  key :coords, Array

  key :metadata, Hash
  key :size, String

  key :group_id, ObjectId, :optional
  key :group_type, String, :optional
  # timestamps

  scope :near_to, lambda {|centre| where(:id => {'$in' => Subject.near(centre)}) }
  
  STATUSES = ['active', 'inactive', 'complete', 'paused', 'disabled']
  
  def is_tutorial?
    return self.respond_to?('tutorial') ? TRUE : FALSE
  end

  def classifications
    Classification.where(:subject_ids => [Subject.find_by_zooniverse_id(self.zooniverse_id).id])
  end

  def user_names
    self.classifications.map{|c|c.user_name}.uniq
  end
  
  def self.counts
    c = {}
    for status in STATUSES
      c[status] = Subject.count(:state => status)
    end
    c
  end

  def annotations
    # type_key = Milkman::Application.config.project["type_key"]
    task_keys = ["illustration", "parts", "details"]
    unless self.is_tutorial? #Exclude tutorial
      list = self.classifications.map{|c| c.annotations }.flatten.select{|i| task_keys.include?(i["key"]) && i["value"].is_a?(Hash) }.map{|a| a["value"].map{|k,v| v}}.flatten
    else
      return nil
    end
  end

  def save_scan(data, eps, min, type="dbscan")
    s = ScanResult.create(
      :zooniverse_id => self.zooniverse_id,
      :subject_id => self.id,
      :type => type,
      :eps => eps,
      :min =>  min,
      :state => self.state,
      :classification_count => self.classification_count,
      :annotations => data
    )
    puts "Created data for #{self.zooniverse_id}"
    return s.annotations
  end

  def self.random
    s = Subject.where(:classification_count => {:$gte => Milkman::Application.config.project["min_random"]})
    s.skip(rand(s.size-1)).first
  end

  def annotations_by_type(o="adult")
    type_key = Milkman::Application.config.project["type_key"]
    begin
      return self.annotations.select{|a| a[type_key]==o if !a.blank?}
    rescue
      return []
    end
  end

  def dbscan_by_type(o,epsilon,min_points)
    output = { "raw"=>[], "reduced"=>[], "noise"=>[] }
    raw_scan = []
    labels = []
    label_keys = Milkman::Application.config.project["object_types"][o]['data_keys']
    objects = self.annotations_by_type(o)
    objects.each do |i|

      output_format = {}
      scan_format = []
      label = {}
      label_keys.each do |k|
        label[k] = i[k]
      end
      labels << label

      Milkman::Application.config.project["dbscan"]["params"].each do |k,v|
        output_format[k] = i[k].to_f
        scan_format << v*i[k].to_f
      end
      output_format['label'] = label

      output["raw"] << output_format
      raw_scan << scan_format

    end

    keys = Milkman::Application.config.project["dbscan"]["params"].keys
    vals = Milkman::Application.config.project["dbscan"]["params"].values
    dbscan = Clusterer.new( raw_scan, {:min_points => min_points.to_i, :epsilon => epsilon.to_f, :labels => labels})
    dbscan.results.each do |k, arr|
      labels = dbscan.labeled_results[k]
      unless k==-1
        
        signals=[]
        averages={}
        qualities={}
        averages['labels'] = []
        arr.each_with_index do |a,m|
          item = {}
          a.each_with_index do |i,n|
            item[keys[n]] = (i/vals[n]).to_s=="NaN" ? 0.0 : i/vals[n]
          end
          item['label'] = labels[m]
          averages['labels'] << labels[m]
          signals << item
        end

        
        arr.transpose.each_with_index do |a,n|
          averages[keys[n]] = ((a.inject{|sum, el| sum+el }/arr.size)/vals[n]).to_s=="NaN" ? 0.0 : (a.inject{|sum, el| sum+el }/arr.size)/vals[n]
        end

        
        arr.transpose.each_with_index do |a,n|
          qualities[keys[n]] = stdev(a)
        end
        
        averages["quality"] = qualities
        averages["signal"] = signals
        output["reduced"] << averages

      else
        
        noises=[]
        arr.each_with_index do |a,m|
          item = {}
          a.each_with_index do |i,n|
            item[keys[n]] = (i/vals[n]).to_s=="NaN" ? 0.0 : i/vals[n]
          end
          item['label'] = labels[m]
          noises << item
        end
        output["noise"] << noises

      end
    end
    return output
  end

  def cache_scan_result(eps=Milkman::Application.config.project["dbscan"]["eps"], min=Milkman::Application.config.project["dbscan"]["min"])
    res = ScanResult.first(:zooniverse_id => self.zooniverse_id, :eps => eps, :min => min)
    if res.nil?
      puts "Caching result for #{self.zooniverse_id}"
      return self.dbscan(eps,min)
    else
      if (res.created_at < 30.days.ago && res.classification_count == self.classification_count)
        ScanResult.where(:zooniverse_id => self.zooniverse_id, :eps => eps, :min => min).each{|r|r.delete}
        return self.dbscan(eps,min)
        puts "New result saved for #{self.zooniverse_id}"
      else
        # puts "Result found for #{self.zooniverse_id}"
        return res.annotations
      end
    end
  end

  def dbscan(epsilon=Milkman::Application.config.project["dbscan"]["eps"], min_points=Milkman::Application.config.project["dbscan"]["min"])
    types = Milkman::Application.config.project["object_types"].keys
    result = {}
    types.each do |o|
      result[o] = self.dbscan_by_type(o, epsilon, min_points)
    end
    save_scan(result, epsilon, min_points, "dbscan")
    return result
  end

  def self.cache_results(n=10, eps=Milkman::Application.config.project["dbscan"]["eps"], min=Milkman::Application.config.project["dbscan"]["min"])
    completed_ids = ScanResult.all.map{|s|s.zooniverse_id}
    Subject.where(:zooniverse_id.nin => completed_ids, :tutorial.ne => true).sort(:classification_count.desc).limit(n).each do |i|
      i.cache_scan_result(eps, min)
    end
  end

  def self.find_in_range(l,b)
    r = 0.075
    Subject.where(:$or => [{:state => "complete"}, {:state => "legacy"}], :coords => {:$elemMatch => {:$gt => l-r, :$lt => l+r}}).select{|i| i.glat>b-r && i.glat<b+r }
  end

  def self.near(centre)

    distance = 0.075
    regionals = []
    lows  = Subject.where(:coords => {:$elemMatch => {:$gte => centre[0]-distance, :$gte => centre[1]-distance}}).to_a
    lows.each{|s| regionals<<s if s.coords[0]<=centre[0]+distance && s.coords[1]<=centre[1]+distance } # && s.metadata["size"]=="0.1500x0.0750" }

    subjects = {}
    regionals.each do |s|
      dist = Math.sqrt( ((s.coords[0]-centre[0]) * (s.coords[0]-centre[0])) + ((s.coords[1]-centre[1]) * (s.coords[1]-centre[1])) )
      subjects[s.id] = dist
    end

    subjects.values.sort!
    return subjects.select {|k, v| v < distance}.keys

  end

  def self.cache_near(l,b,r)

    completed_ids = ScanResult.all.map{|s|s.zooniverse_id}
    set = Subject.where(:state => "complete", :zooniverse_id.nin => completed_ids, :tutorial.ne => true, :coords => {:$elemMatch => {:$gt => l-r, :$lt => l+r}}).select{|i| i.glat>b-r && i.glat<b+r }
    puts "Found #{set.size} subjects"
    set.each do |i|
      i.cache_scan_result
    end

  end

  def width
    return FastImage.size(self.image[0])[0]
  end

  def height
    return FastImage.size(self.image[0])[1]
  end

  def pixel_scale
  	xs = self.width.to_f/Milkman::Application.config.project["image"]["width"]
  	ys = self.height.to_f/Milkman::Application.config.project["image"]["height"]

  	return xs.round(5)==ys.round(5) ? xs : "scale conflict"
  end

  def image
    self.location["standard"].is_a?(Array) ? self.location["standard"] : [self.location["standard"]]
  end

  def image_count
    self.location["standard"].is_a?(Array) ? self.location["standard"].size : 0
  end

  def object_count(o)
  	self.metadata["markings"] ? self.metadata["markings"][o+"_count"].to_i : 0
  end

  def empty_image?
  	if self.metadata["markings"]
  		if self.object_count("blank")>=5 && self.state=="complete" && self.classification_count<=10
  		  return true
	  	else
	  	  return false
	    end
    else
	    return false
  	end
  end

end
