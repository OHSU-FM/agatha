module LsReportsHelper

  def rc_api
    @rc_api ||= LimeExt::API.new()
  end

  def hf_sidebar_link_label question, full_desc
    (full_desc ? strip_tags(question.question) : question.title.titleize).html_safe
  end


  class AccessDenied < Exception; end

  MAX_Q = 10

  ##
  # Generate a unique cache key for this Group ID (and its user's filters)
  def cache_key_for_group virt_group, opts={}
    group = virt_group.group
    query = group.lime_survey.lime_data.query
    updated_at = group.lime_survey.role_aggregate.updated_at
    gid = group.gid
    "ls_reports/show_part/updated_at=#{updated_at}/query=#{query}/gid=#{gid}/view_type=#{opts[:view_type]}/for=#{opts[:for]}"
  end

  def lime_file_links question
    raise 'Not a file question' unless question.qtype == 'file_upload'
    links = []
    ldata = question.response_set.data || []
    ldata.each do |dat|
      f_links = []
      dat_files = dat[:files] || []
      dat_files.each do |finfo|
        link = link_to(
          finfo['name'],
          lime_file_path(:sid=>question.survey.sid, :row_id=>dat[:row_id], :name=>finfo['name'], :qid=>question.qid)
        )
        f_links.push link
      end
      links.push f_links
    end
    return links
  end

  def hf_group_title(title)
    title.include?(":") ? title.split(":").last(2).join(" - ") : title
  end

  def hf_role_aggregate_groups(role_aggregates)
    result = {}
    rc_api.list_surveys().map{|ls|
      ra = RoleAggregate.find_by(virtual_survey_sid: ls["sid"])
      next unless ra.present?
      title = ls["surveyls_title"].rpartition(":")
      result[title.first] = [] unless result.keys.include? title.first
      result[title.first].push([title.last, ra])
    }
    result
  end

  # Does this user have a widget for this pk, agg and question?
  def user_has_widget? user, question, pk, agg, view_type, graph_type
    !user.question_widgets.find{|qw|
      qw.lime_question_qid == question.qid &&
        qw.agg=agg.to_s && qw.pk==pk.to_s &&
        qw.view_type.to_s == view_type.to_s &&
        qw.graph_type.to_s == graph_type.to_s
    }.nil?
  end
end
