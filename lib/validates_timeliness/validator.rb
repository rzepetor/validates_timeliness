require 'active_model/validator'

module ValidatesTimeliness
  class Validator < ActiveModel::EachValidator
    include Conversion

    RESTRICTIONS = {
      :is_at        => :==,
      :before       => :<,
      :after        => :>,
      :on_or_before => :<=,
      :on_or_after  => :>=,
    }.freeze

    def self.kind
      :timeliness
    end

    def initialize(options)
      @allow_nil, @allow_blank = options.delete(:allow_nil), options.delete(:allow_blank)
      @type = options.delete(:type)

      if range = options.delete(:between)
        raise ArgumentError, ":between must be a Range or an Array" unless range.is_a?(Range) || range.is_a?(Array)
        options[:on_or_after], options[:on_or_before] = range.first, range.last
      end
      super
    end

    def check_validity!
    end

    def validate_each(record, attr_name, value)
      raw_value = attribute_raw_value(record, attr_name) || value
      return if (@allow_nil && raw_value.nil?) || (@allow_blank && raw_value.blank?)

      return record.errors.add(attr_name, :"invalid_#{@type}") if value.blank?

      value = type_cast(value)

      (RESTRICTIONS.keys & options.keys).each do |restriction|
        restriction_value = type_cast(evaluate_option_value(options[restriction], record))
        unless value.send(RESTRICTIONS[restriction], restriction_value)
          return record.errors.add(attr_name, restriction, :restriction => restriction_value)
        end
      end
    end

    def attribute_raw_value(record, attr_name)
      before_type_cast = "#{attr_name}_before_type_cast"
      record.send("#{attr_name}_before_type_cast") if record.respond_to?(before_type_cast)
    end

    def type_cast(value)
      type_cast_value(value, @type)
    end
  end
end

# Compatibility with ActiveModel validates method which tries match option keys to their validator class
TimelinessValidator = ValidatesTimeliness::Validator