module LimeExt
  class VirtualSurvey
    attr_reader :sid, :rc_api

    CONFIG_GROUP_CODE   = "ReindeerConfig"
    QRESPONSE_STATUS_CODE = "responseStatus"

    def initialize sid, api
      @sid = sid
      @rc_api = api
    end

    def title
      @title ||= @rc_api.list_surveys().select{|s| s["sid"] == @sid}.first["surveyls_title"]
    end

    def group_and_title_name
      parts = title.rpartition(":")
      return parts.first, parts.last
    end

    def virtual_groups
      @virtual_groups ||= build_virtual_groups
    end

    def virtual_questions
      virtual_groups.map{|g| g.virtual_questions}.flatten
    end

    def build_virtual_groups
      virtual_groups = []
      survey_groups.each do |g|
        virtual_groups << Group.new(self, g, @rc_api)
      end
      virtual_groups
    end

    def survey_groups
      @survey_groups ||= @rc_api.list_groups(@sid)
    end

    def survey_questions
      @survey_questions ||= @rc_api.list_questions(@sid)
    end

    def survey_responses
      @survey_responses ||= JSON.parse(Base64.decode64(@rc_api
        .export_responses(@sid, "json")
                                                      )
                                      )["responses"].map{|r| r.values.first}
    end

    def role_aggregate
      RoleAggregate.find_by(virtual_survey_sid: @sid)
    end

    def lime_data
      raise "sid not set" unless @sid
      @lime_data ||= LimeExt::LimeData.new(self)
    end

    def lime_stats
      @lime_stats ||= LimeExt::LimeStat::LimeStat.new(self)
    end

    def wipe_response_sets
      virtual_questions.each {|q| q.wipe_response_set}
      return nil
    end

    def find_question key, value
      virtual_groups.each do |group|
        group.virtual_questions.each do |question|
          return question if question.send(key) == value
        end
      end
      return nil
    end

    def status_questions
      return [] unless @sid
      return @status_questions if defined? @status_questions
      vgroup = virtual_groups.select{|g| g.group_name == CONFIG_GROUP_CODE}
      return [] if vgroup.empty?
      pquestion = vgroup.parent_questions.select{|pquestion|
        pquestion.title == QRESPONSE_STATUS_CODE
      }
      return [] if pquestion.empty?
      @status_questions = pquestion.sub_questions
    end

    # returns list of question.my_column_name for survey qs
    def column_names
      virtual_questions.select{|q|
        q.is_sq? || !q.has_sq?
      }.map{|q| q.rc_resp_name }
    end

    def add_filter col, val, opts={}
      lime_data.add_filter col, val, opts
    end

    class Group
      attr_reader :survey

      def initialize survey, group_hash, api
        @survey = survey
        @group_hash = group_hash
        @rc_api = api
      end

      def virtual_questions
        @virtual_questions ||= build_virtual_questions
      end

      def parent_questions
        @parent_questions ||= virtual_questions.select{|q| q.parent_qid == 0}
      end

      def build_virtual_questions
        v_questions = []
        survey.survey_questions.each {|q|
          next if q["gid"] != gid
          v_questions << Question.new(@survey, q, @rc_api)
        }
        v_questions.sort_by {|q| q.qid }
      end

      def group_name
        @group_hash["group_name"]
      end

      def group_order
        @group_hash["group_order"]
      end

      def gid
        @group_hash["gid"]
      end
    end

    class Question
      attr_reader :survey, :gid, :qid, :q_hash

      # Question types used by LimeSurvey and the short names we use for partials
      QTYPES = {
        '1'=>'dual_arr',          # - Array (Flexible Labels) Dual Scale
        '5'=>'five_point',        # - 5 Point Choice
        'A'=>'arr_five',          # - Array (5 Point Choice)
        'B'=>'arr_ten',           # - Array (10 Point Choice)
        'C'=>'arr_ynu',           # - Array (Yes/No/Uncertain)
        'D'=>'date',              # - Date
        'E'=>'arr_isd',           # - Array (Increase, Same, Decrease)
        'F'=>'arr_flex',          # - Array (Flexible Labels)
        'G'=>'gender',            # - Gender
        'H'=>'arr_flex_col',      # - Array (Flexible Labels) by Column
        'I'=>'lang',              # - Language Switch
        'K'=>'mult_numeric',      # - Multiple Numerical Input
        'L'=>'list_radio',        # - List (Radio)
        'M'=>'mult',              # - Multiple choice
        'N'=>'numeric',           # - Numerical Input
        'O'=>'list_comment',      # - List With Comment
        'P'=>'mult_w_comments',   # - Multiple choice with comments
        'Q'=>'mult_short_text',   # - Multiple Short Text
        'R'=>'rank',              # - Ranking
        'S'=>'short_text',        # - Short Free Text
        'T'=>'long_text',         # - Long Free Text
        'U'=>'huge_text',         # - Huge Free Text
        'X'=>'boiler',            # - Boilerplate Question
        'Y'=>'yes_no',            # - Yes/No
        '!'=>'list_drop',         # - List (Dropdown)
        ':'=>'arr_mult_drop',     # - Array (Flexible Labels) multiple drop down
        ';'=>'arr_mult_text',     # - Array (Flexible Labels) multiple texts
        '|'=>'file_upload'        # - File Upload Question
      }

      def initialize survey, q_hash, api
        @survey = survey
        @q_hash = q_hash
        @rc_api = api
      end

      def type
        @q_hash["type"]
      end

      def qtype
        QTYPES[@q_hash["type"]]
      end

      def group
        @survey.virtual_groups.select{|g| g.gid == @q_hash["gid"]}.first
      end

      def question
        @q_hash["question"]
      end

      def lime_answers
        return @lime_answers if defined? @lime_answers
        retval = @rc_api.get_question_properties(qid, ["answeroptions"])
        @lime_answers = if retval["answeroptions"] == "No available answer options"
          []
        else
          ret = []
          retval["answeroptions"].each do |code, ans_h|
            ret << Answer.new(code, ans_h)
          end
          ret
        end
        @lime_answers
      end

      def attributes
        @attributes ||= @rc_api.get_question_properties(qid, ["attributes"])
      end

      def response_set
        @response_set ||= LimeExt::ResponseLoaders.responses_for self
      end

      def stats
        if is_sq?
          parent_question.stats.sub_stats.select{|ss| ss.question.qid == qid}
        else
          survey.lime_stats.generate_stats_for_question self
        end
      end

      def gid
        @q_hash["gid"]
      end

      def qid
        @q_hash["qid"]
      end

      def title
        @q_hash["title"]
      end

      def parent_qid
        @q_hash["parent_qid"]
      end

      def parent_question
        group.parent_questions.select{|q| q.qid == parent_qid }.first
      end

      def is_sq?
        @q_hash["parent_qid"] > 0
      end

      def has_sq?
        sub_questions.count > 0
      end

      def sub_questions
        group.virtual_questions.select{|q| q.parent_qid == qid }
      end

      def hidden?
        attributes["attributes"] == {"hidden" => "1"}
      end

      def num_value_int_only?
        attributes["attributes"] == {"num_value_int_only" => "1"}
      end

      # column name as it's served via rc json api
      # @return [String] is_sq? ? parent.title[sq.title] : parent.title
      def rc_resp_name
        @rc_resp_name ||= if is_sq?
                            "#{parent_question.title}[#{title}]"
                          else
                            title
                          end
      end

      def my_column_name
        warn "[DEPRECATION] use #rc_resp_name instead. "\
          "called from #{Kernel.caller.first}"
        return @my_column_name if defined? @my_column_name
        if is_sq?
          @my_column_name = "#{survey.sid}X#{group.gid}X#{parent_qid}#{title}"
        else
          @my_column_name = "#{survey.sid}X#{group.gid}X#{qid}"
        end
        return @my_column_name
      end

      def wipe_response_set
        @wipe_response_set = true
      end

      def lime_data
        @survey.lime_data
      end
    end

    class Answer
      attr_accessor :code

      def initialize code, hash
        @code = code
        @ans_h = hash
      end

      def method_missing name, *args
        if @ans_h[name.to_s].nil?
          super
        else
          @ans_h[name.to_s]
        end
      end
    end
  end
end
