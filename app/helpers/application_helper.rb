module ApplicationHelper
  # Unified icon helper for Heroicons and custom SVGs
  #
  # Examples:
  #   <%= icon 'phone', classes: 'w-5 h-5 text-sage-600' %>
  #   <%= icon 'star', variant: :solid, classes: 'w-5 h-5 text-amber-400' %>
  #   <%= icon 'quote', variant: :custom %>
  #
  def icon(name, variant: :outline, classes: "w-6 h-6", **options)
    case name.to_s
    when "quote"
      render_custom_quote_icon(classes, options)
    when "instagram"
      render_custom_instagram_icon(classes, options)
    when "branch"
      render_custom_branch_icon(classes, options)
    else
      heroicon(name, variant: variant, options: { class: classes }.merge(options))
    end
  end

  # Centralized booking URL with sensible fallback to phone
  # Booking CTA target, best available first: the native on-site flow (when
  # Square API creds are configured), else the external Square booking page
  # (BOOKING_URL), else the phone line.
  def booking_link
    return book_path if SquareApi.configured?

    ENV["BOOKING_URL"].presence || "tel:+17048249032"
  end

  # Google reviews/business URL with a sensible fallback to a Maps search.
  # Set GOOGLE_REVIEWS_URL to the salon's Google Business "reviews" or place link.
  def google_reviews_link
    ENV["GOOGLE_REVIEWS_URL"].presence ||
      "https://www.google.com/maps/search/?api=1&query=Elite+Nails+202+Market+St+Cramerton+NC"
  end

  # Single source of truth for the salon's name/address/phone (NAP), geo, price
  # range, and founding year — backed by the SiteSetting record (falls back to
  # SiteSetting::DEFAULTS when unset). Hours live in BusinessHour. Returns the
  # SiteSetting instance; call attributes directly (e.g. `salon.phone_display`).
  def salon
    SiteSetting.current
  end

  # Keyless Google Maps embed URL for the salon address (no API key required).
  def salon_map_embed_url
    query = "#{salon.street}, #{salon.city}, #{salon.region} #{salon.postal_code}"
    "https://www.google.com/maps?q=#{ERB::Util.url_encode(query)}&output=embed"
  end

  # Existing service records retain their legacy image filename while the site
  # serves the matching responsive WebP variants.
  def responsive_service_image_sources(image)
    base_name = File.basename(image.to_s, File.extname(image.to_s)).sub(/-(?:480|768)\z/, "")
    # Every name here must have BOTH a -480.webp and a -768.webp in
    # app/assets/images, at exactly those pixel widths — the srcset descriptors
    # below are hardcoded, so a mismatch tells the browser the wrong size.
    # A name missing from this list still renders, but silently loses its
    # srcset and serves the full 768 to phones.
    responsive = %w[
      manicure-service pedicure-service nail-art-service
      acrylic-service nail-care-service waxing-service
    ]
    return { src: asset_path(image) } unless responsive.include?(base_name)

    {
      src: asset_path("#{base_name}-768.webp"),
      srcset: [
        "#{asset_path("#{base_name}-480.webp")} 480w",
        "#{asset_path("#{base_name}-768.webp")} 768w"
      ].join(", ")
    }
  end

  # Placeholder image helper (currently disabled - returns nil)
  # Kept for future use when actual images are added
  #
  # Examples:
  #   <%= placeholder_image(width: 800, height: 600, seed: 'hero') %>
  #
  def placeholder_image(width: nil, height: nil, seed: nil, grayscale: false, blur: 0)
    # Return nil to show placeholder backgrounds instead of images
    nil
  end

  private

  def render_custom_quote_icon(classes, options)
    content_tag(:svg, class: classes, fill: "currentColor", viewBox: "0 0 24 24", **options) do
      tag.path(d: "M14.017 21v-7.391c0-5.704 3.731-9.57 8.983-10.609l.995 2.151c-2.432.917-3.995 3.638-3.995 5.849h4v10h-9.983zm-14.017 0v-7.391c0-5.704 3.748-9.57 9-10.609l.996 2.151c-2.433.917-3.996 3.638-3.996 5.849h3.983v10h-9.983z")
    end
  end

  def render_custom_instagram_icon(classes, options)
    content_tag(:svg, class: classes, fill: "currentColor", viewBox: "0 0 24 24", **options) do
      tag.path(d: "M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z")
    end
  end

  def render_custom_branch_icon(classes, options)
    content_tag(:svg, class: classes, fill: "none", viewBox: "0 0 100 200", **options) do
      safe_join([
        tag.path(d: "M50 200 C 20 150, 10 100, 50 50 C 30 80, 25 120, 50 200", stroke: "currentColor", "stroke-width": "1", fill: "none"),
        tag.path(d: "M50 180 C 60 140, 80 120, 95 100", stroke: "currentColor", "stroke-width": "1", fill: "none"),
        tag.path(d: "M50 150 C 60 120, 75 100, 90 80", stroke: "currentColor", "stroke-width": "1", fill: "none"),
        tag.path(d: "M50 120 C 40 100, 25 80, 10 60", stroke: "currentColor", "stroke-width": "1", fill: "none")
      ])
    end
  end
end
