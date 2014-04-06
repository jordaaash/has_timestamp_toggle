require 'has_timestamp_toggle/version'
require 'active_record/base'

module HasTimestampToggle
  def has_timestamp_toggle (options = {})
    options = {
      :states        => [:enabled, :disabled], # :shown, :hidden | :unread, :read
      :actions       => [:enable, :disable], # :show, :hide    | :mark_unread, :mark_read,
      :column        => nil,
      :default_scope => true
    }.merge!(options)

    default_state, alternate_state   = options[:states]
    default_action, alternate_action = options[:actions]

    column = options[:column] || :"#{alternate_state}_at"

    scope default_state, -> { where(column => nil) }
    scope alternate_state, -> { where.not(column => nil) }
    default_scope -> { where(column => nil) } if options[:default_scope]

    class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
      def #{default_state}?                                                         # def enabled?
        #{column}.nil?                                                              #   disabled_at.nil?
      end                                                                           # end
      alias_method :is_#{default_state}, :#{default_state}?                         # alias_method :is_enabled, :enabled?

      def #{alternate_state}?                                                       # def disabled?
        !#{column}.nil?                                                             #   !disabled_at.nil?
      end                                                                           # end
      alias_method :is_#{alternate_state}, :#{alternate_state}?                     # alias_method :is_disabled, :disabled?

      def is_#{default_state}= (is_#{default_state})                                # def is_enabled= (is_enabled)
        if is_#{default_state} == true || is_#{default_state}.to_s == '1'           # if is_enabled == true || is_enabled.to_s == '1'
          #{default_action}                                                         #     enable
          true                                                                      #     true
        elsif is_#{default_state} == false || is_#{default_state}.to_s == '0'       #   elsif is_enabled == false || is_enabled.to_s == '0'
          #{alternate_action}                                                       #     disable
          false                                                                     #     false
        else                                                                        #   else
          raise ArgumentError, 'is_#{default_state} must be true, false, 1, or 0'   #     raise ArgumentError, 'is_enabled must be true, false, 1, or 0'
        end                                                                         #   end
      end                                                                           # end

      def is_#{alternate_state}= (is_#{alternate_state})                            # def is_disabled= (is_disabled)
        if is_#{alternate_state} == true || is_#{alternate_state}.to_s == '1'       #   if is_disabled == true || is_disabled.to_s == '1'
          #{alternate_action}                                                       #     disable
          true                                                                      #     true
        elsif is_#{alternate_state} == false || is_#{alternate_state}.to_s == '0'   #   elsif is_disabled == false || is_disabled.to_s == '0'
          #{default_action}                                                         #     enable
          false                                                                     #     false
        else                                                                        #   else
          raise ArgumentError, 'is_#{alternate_state} must be true, false, 1, or 0' #     raise ArgumentError, 'is_disabled must be true, false, 1, or 0'
        end                                                                         #   end
      end                                                                           # end

      def #{default_action}                                                         # def enable
        self.#{column} &&= nil                                                      #   self.disabled_at &&= nil
      end                                                                           # end

      def #{alternate_action}                                                       # def disable
        self.#{column} ||= Time.now.utc                                             #   self.disabled_at ||= Time.now.utc
      end                                                                           # end

      def #{default_action}!                                                        # def enable!
        #{alternate_state}? ? update_column(:#{column}, nil) : true                 #   disabled? ? update_column(:disabled_at, nil) : true
      end                                                                           # end

      def #{alternate_action}!                                                      # def disable!
        #{default_state}? ? update_column(:#{column}, Time.now.utc) : true          #   enabled? ? update_column(:disabled_at, Time.now.utc) : true
      end                                                                           # end
    RUBY_EVAL
  end
end

ActiveRecord::Base.send :extend, HasTimestampToggle
