class CatalogueObjectsController < ApplicationController
  def bubbles
    @pagetitle = Milkman::Application.config.project["name"]
    @bubbles = CatalogueObject.where(:type => 'bubble', :catalogue_name => 'DR2')

    # render "catalogue_objects/bubbles"
  end
end
