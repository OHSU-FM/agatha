module LimeExt
  class FilterManager
    attr_reader :hide_pk, :hide_agg, :lime_survey, :lime_survey_unfiltered, :pk,
      :agg, :pk_enum, :agg_enum, :params, :user, :filters_equal, :series_name,
      :unfiltered_series_name

    def initialize user, sid, rc_api, opts={}
      @user = user
      @ability = Ability.new user
      @sid = sid
      @rc_api = rc_api
      @hide_agg = opts[:hide_agg] || false
      @hide_pk = opts[:hide_pk] || false
      @params = opts[:params].is_a?(Hash) ? opts[:params] : {}
      add_all_param_filters
      do_titles
    end

    # Aliases

    def role_aggregate
      @role_aggregate ||= RoleAggregate.find_by(virtual_survey_sid: @sid)
    end

    def lime_survey
      @lime_survey ||= virtual_survey
    end

    def lime_survey_unfiltered
      @lime_survey ||= virtual_survey
    end

    def virtual_survey
      @virtual_survey ||= VirtualSurvey.new @sid, @rc_api
    end

    # Generate array of virtual groups
    def virtual_groups
      @virtual_groups ||= virtual_survey.virtual_groups
    end

    # Agg enumerator for links
    def agg_enum
      # Enums for filtering in view
      # NO BYREF - Dup array first
      @agg_enum ||= role_aggregate.agg_enum.dup.unshift(['All', ''])
    end

    # PK enumerator for links
    # NO BYREF - Dup array first
    def pk_enum
      @pk_enum ||= role_aggregate.pk_enum.dup.unshift( ['All', '_' ])
    end

    def filters_equal
      lime_survey.lime_data.filters == lime_survey_unfiltered.lime_data.filters
    end

    # Add user lime permissions to lime_survey
    def add_permission_group_filters
      unless @ability.can? :read, lime_survey
        raise LsReportsHelper::AccessDenied
      end

      unless @ability.can? :read_unfiltered, lime_survey
        # Filters for comparison
        plg = user.permission_group.permission_ls_groups.where(:lime_survey_sid=>lime_survey.sid).first
        raise "Permissions Error: User cannot access this survey" unless plg.present?
        plg.permission_ls_group_filters.each do |plgk|
          fieldname = plgk.lime_question.my_column_name
          if plgk.restricted_val.present?
            filter_val = plgk.restricted_val
          else
            uex = plgk.user_externals.where(:user_id=>@user.id).first
            raise 'Permissions Error: UserExternal is missing' unless uex.present?
            filter_val = uex.filter_val
          end
          add_x_filters fieldname, filter_val, plgk.filter_all
        end
      end
      @hide_agg = true if role_aggregate.agg_fieldname.to_s.empty?
    end

    # Add a filter to one or both datasets/surveys
    def add_x_filters fieldname, filter_val, filter_all
      # Add filter to filtered dataset
      lime_survey.add_filter fieldname, filter_val

      # Filter both if the ULP says to
      if filter_all
        lime_survey_unfiltered.add_filter fieldname, filter_val
      end
    end

    # Add filters from params
    def add_all_param_filters
      agg_enum # Load and cache agg_enum

      unless @hide_agg
        @agg = add_param_filter lime_survey, :agg, role_aggregate.agg_fieldname
        # Make sure unfiltered dataset has agg filtered
        add_param_filter lime_survey_unfiltered, :agg, role_aggregate.agg_fieldname
      end

      pk_enum # Load and cache pk_enum

      unless @hide_pk
        @pk = add_param_filter lime_survey, :pk, role_aggregate.pk_fieldname
        # default to last val if only one pk option
        @pk.nil? ? @pk = @pk_enum.first[1] : @pk
      end
    end

    # Add a filter to a survey
    def add_param_filter cur_survey, filter_name, fieldname
      return nil if fieldname.to_s.empty?            # No filter to use
      return nil if @params[filter_name].to_s.empty? # No filter val specified
      filter_val = @params[filter_name]
      return nil if filter_val == '_'                # Blank filter val specified
      cur_survey.add_filter(fieldname, filter_val)   # Add filter
      return filter_val
    end

    # Generate titles for each series
    def do_titles
      @series_name = build_title(lime_survey).map{|k,v|"#{k}(#{v})"}.join(', ')
      @unfiltered_series_name = build_title(lime_survey_unfiltered).map{|k,v|"#{k}(#{v})"}.join(', ')
    end

    # Build the title for an individual dataset
    def build_title survey
      result = []
      ra = survey.role_aggregate
      survey.lime_data.filters.uniq.each do |filter|
        # Check agg_enum for a match to this value
        title = get_title ra.agg_enum, filter[:val]
        result.push([ra.get_agg_label, title]) if title
        next if title # Found match for this filter, do next filter

        title = get_title ra.pk_enum, filter[:val]
        result.push([ra.get_pk_label, title]) if title
      end
      return result.uniq
    end

    # Helper for title builder
    def get_title enum, filter_val
      if enum
        enum.each{|key, val| return key if val == filter_val }
      end
      return nil
    end

  end
end
