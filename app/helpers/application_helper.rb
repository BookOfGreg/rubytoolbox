# frozen_string_literal: true

module ApplicationHelper
  include ComponentHelpers
  include StatsHelpers

  def metric_icon(metric)
    "fa-" + t(:icon, scope: "metrics.#{metric}")
  end

  def metric_label(metric)
    t(:label, scope: "metrics.#{metric}")
  end

  # This should be refactored...
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def pretty_metric_value(value)
    if value.is_a?(Float) || value.is_a?(BigDecimal)
      number_with_delimiter(value.floor) + "%"
    elsif value.is_a? Integer
      number_with_delimiter value
    elsif value.is_a?(Date) || value.is_a?(Time)
      content_tag "time", "#{time_ago_in_words(value)} ago", datetime: value.iso8601, title: l(value)
    elsif value.is_a? Array
      value.to_sentence
    else
      value
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  #
  # A little utility method for displaying project rankings like most downloaded gems
  # in metrics docs pages without too much repetition of in-view logic
  #
  # rubocop:disable Metrics/ParameterLists It's not great but I'm ok with it here
  def project_ranking(title, scope: Project.for_display, table:, column:, direction: "DESC", description: nil)
    projects = scope.order("#{table}.#{column} #{direction} NULLS LAST").limit(100)
    metrics = if table == :github_repos
                ["github_repo_stargazers_count", "github_repo_#{column}"].uniq
              else
                ["rubygem_downloads", "rubygem_#{column}"].uniq
              end

    project_list projects, title: title, metrics: metrics, description: description
  end
  # rubocop:enable Metrics/ParameterLists

  def docs
    @docs ||= Docs.new
  end

  def link_to_docs_if_exists(page, &block)
    content = capture(&block)

    if docs.find page
      link_to content, page_path(page)
    else
      content
    end
  end

  # Render given text as markdown. Do not use this with unsafe
  # inputs as it does not use any blacklisting or sanitization!
  def markdown(text)
    Redcarpet::Markdown.new(
      Redcarpet::Render::HTML,
      autolink: true,
      tables:   true
    ).render(text).html_safe # rubocop:disable Rails/OutputSafety
  end

  #
  # Creates a link to the current page respecting all display mode & search query
  # url arguments available in project listings (mode, order, search query, bugfix forks)
  #
  # This logic depends on too much implicit state by gathering bits & pieces
  # from various assumed assigned variables, maybe extraction to some wrapping
  # object might make sense...
  #
  def link_with_preserved_display_settings(**args)
    addressable = Addressable::URI.new.tap do |uri|
      uri.query_values = default_display_settings.merge(args).compact
    end
    "#{request.path}?#{addressable.query}"
  end

  def default_display_settings
    {
      order:      try(:current_order)&.ordered_by,
      q:          @search&.query,
      show_forks: @search&.show_forks,
      display:    @display_mode&.current,
    }
  end

  # why
  # https://rails.lighthouseapp.com/projects/8994/tickets/4334-to_param-and-resource_path-escapes-forward-slashes
  # https://github.com/rails/rails/issues/16058
  def blog_post_path(post)
    File.join blog_index_path, post.slug
  end

  # See above.
  def blog_post_url(post)
    File.join blog_index_url, post.slug
  end

  # Just to make sure to never mess up using url instead of path or the wrong format.
  def feed_url
    blog_index_url(format: :rss)
  end

  def site_name
    t(:name)
  end

  def tagline
    t(:tagline)
  end

  def title(default: false)
    if !default && content_for(:title).present?
      [content_for(:title), site_name].join(" - ")
    else
      [site_name, tagline].join(" - ")
    end
  end

  def description
    content_for(:description).presence || t(:description)
  end

  def active_when(controller:)
    "is-active" if controller_name == controller.to_s
  end
end
