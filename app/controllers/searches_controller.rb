class SearchesController < ApplicationController
  def index
    @all_pharmacies = PharmacyConfig.load_all.select(&:enabled?)
    @query = params[:q].to_s.strip.presence
    return unless @query

    @selected_slugs = params[:pharmacies].present? ? Array(params[:pharmacies]) : @all_pharmacies.map(&:slug)
    @pharmacies = @all_pharmacies.select { |p| @selected_slugs.include?(p.slug) }

    @cached_results = {}
    pending = []

    @pharmacies.each do |config|
      cached = SearchJob.read_cache(@query, config.slug)
      cached ? @cached_results[config.slug] = cached : pending << config
    end

    if pending.any?
      @stream_name = stream_name_for(@query)
      pending.each do |config|
        SearchJob.perform_later(query: @query, pharmacy_slug: config.slug, stream_name: @stream_name)
      end
    end
  end

  private

  def stream_name_for(query)
    "search-#{current_user.id}-#{Digest::MD5.hexdigest(query.downcase.strip)}"
  end
end
