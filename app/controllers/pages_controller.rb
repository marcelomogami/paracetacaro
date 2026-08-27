class PagesController < ApplicationController
  def changelog
    @changelog = Rails.root.join("CHANGELOG.md").read
  end
end
