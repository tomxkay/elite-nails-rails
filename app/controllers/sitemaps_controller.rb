# XML sitemap for search engines. The public site is a single page plus the
# booking flow, so the sitemap is small and built inline. URLs use the
# canonical host (CANONICAL_HOST) when set so they match the indexed domain.
class SitemapsController < ApplicationController
  def show
    @base_url = ENV["CANONICAL_HOST"].present? ? "https://#{ENV['CANONICAL_HOST']}" : request.base_url
    @pages = [
      { path: "/", changefreq: "weekly", priority: "1.0" },
      { path: "/book", changefreq: "monthly", priority: "0.8" }
    ]
    render layout: false, content_type: "application/xml"
  end
end
