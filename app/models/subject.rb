require 'open-uri'
require 'json'

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

  def is_tutorial?
    return self.respond_to?('tutorial') ? TRUE : FALSE
  end

  def classifications
    Classification.where(:subject_ids => [Subject.find_by_zooniverse_id(self.zooniverse_id).id])
  end

  def user_names
    self.classifications.map{|c|c.user_name}.uniq
  end

  def annotations
    unless self.is_tutorial? #Exclude tutorial
      list = self.classifications.map{|c|c.annotations}.map{|a| a[0].dig("value")}.map{|a| a.map{|k,v| v} if a.is_a?(Hash)}.flatten
    else
      return nil
    end
  end

  def save_scan(data, type="dbscan")
    s = ScanResult.create(
      :zooniverse_id => self.zooniverse_id,
      :subject_id => self.id,
      :type => type,
      :state => self.state,
      :classification_count => self.classification_count,
      :annotations => data
    )
    puts "Created data for #{self.zooniverse_id}"
    return s.annotations
  end

  def self.random
    s = ScanResult.where(:classification_count => {:$gte => Milkman::Application.config.project["min_random"]})
    s.skip(rand(s.size-1)).first
  end

  def annotations_by_type(o="adult")
    # self.annotations.select{|a| a if a["value"]==o}
    begin
      return self.annotations.select{|a| a["value"]==o if !a.blank?}
    rescue
      return []
    end
  end

  def dbscan_by_type(o,min_points,epsilon)
    output = { "raw"=>[], "reduced"=>[], "signal"=>{}, "noise"=>[] }
    raw_scan = []
    objects = self.annotations_by_type(o)
    objects.each do |i|

      if ["adult", "chick", "egg"].include?(o)
        output["raw"] << [i["x"].to_f, i["y"].to_f, 0 ]
        raw_scan << [i["x"].to_f, i["y"].to_f, 0 ]
      end

      if ["vertex", "weird"].include?(o)
        output["raw"] << [i["x"].to_f, i["y"].to_f, i["frame"].to_i ]
        raw_scan << [i["x"].to_f, i["y"].to_f, 1000*i["frame"].to_i ]
      end

    end

    dbscan = Clusterer.new( raw_scan, {:min_points => min_points, :epsilon => epsilon})
    dbscan.results.each do |k, arr|
      unless k==-1
        output["signal"]["#{k}"] = arr.map{|i| { "x" => i[0], "y" => i[1], "frame" => i[2]/1000} }

        avx   = arr.transpose[0].inject{|sum, el| sum+el }.to_f/arr.size
        avy   = arr.transpose[1].inject{|sum, el| sum+el }.to_f/arr.size

        avf   = arr.transpose[2].inject{|sum, el| sum+el }.to_f/arr.size
        avf = 0 if avf==nil

        qy  = stdev(arr.transpose[0])
        qx  = stdev(arr.transpose[1])

        quality = { "qx"=>qx, "qy"=>qy }

        output["reduced"] << { "x" => avx, "y" => avy, "frame" => avf/1000, "quality" => quality }
      else
        output["noise"] = arr.map{|i| { "x" => i[0], "y" => i[1], "frame" => i[2]/1000 } }
      end
    end
    return output
  end

  def cache_scan_result()
    res = ScanResult.first(:zooniverse_id => self.zooniverse_id)
    if res.nil?
      puts "Caching result for #{self.zooniverse_id}"
      return self.dbscan
    else
      if (res.created_at < 30.days.ago && res.classification_count == self.classification_count)
        ScanResult.find_all_by_zooniverse_id(self.zooniverse_id).each{|r|r.delete}
        return self.dbscan
        puts "New result saved for #{self.zooniverse_id}"
      else
        # puts "Result found for #{self.zooniverse_id}"
        return res.annotations
      end
    end
  end

  def dbscan(min_points=Milkman::Application.config.project["dbscan"]["min"], epsilon=Milkman::Application.config.project["dbscan"]["eps"])
    types = Milkman::Application.config.project["object_types"]
    result = {}
    types.each do |o|
      result[o] = self.dbscan_by_type(o,min_points, epsilon)
    end
    save_scan(result, "dbscan")
    return result
  end

  def self.cache_results(n=10)
    completed_ids = ScanResult.all.map{|s|s.zooniverse_id}
    Subject.where(:zooniverse_id.nin => completed_ids, :tutorial.ne => true).sort(:classification_count.desc).limit(n).each do |i|
      i.cache_scan_result
      k+=1
      puts "#{k}/#{n}"
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
    return Milkman::Application.config.project["image"]["width"]/Milkman::Application.config.project["image"]["height"]
  end

  def height
    return 1.0
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
