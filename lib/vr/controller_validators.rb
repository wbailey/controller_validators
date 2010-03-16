# This is a mixin that is meant to provide AR like validators to our controller code.  The primary
# reason for the creation of this class was for security purposes and the params hash.  It is a 
# best practice to validate the data in the hash before any assigment or usage since malicious
# code be posted or provided on the query string.
module VR
  module ControllerValidators
    @@options = {
      :allow_nil => false,
      :only_integer => false,
    }.freeze

    class ValidationException < ArgumentError; end #nodoc

    # Validates whether the Object type of the provide value matches the supplied type.  This is
    # very similar to writing <tt>obj.is_a?( Array )</tt> for example, but has the option of 
    # allowing for nils.
    #
    #   validate_type_of( params[:ids], Array, :allow_nil => true )
    #
    # Configuration Options:
    # * <tt>:allow_nil</tt> - Skip the validation if the supplied value is nil
    def validate_type_of( value, type, caller_options = {} )
      options = @@options.merge( caller_options )

      return true if options[:allow_nil] && value.nil?

      return value.is_a?( type )
    end
    
    # Performs the same validation as <tt>validate_type_of</tt> with failure raising a <tt>ValidationException</tt>.
    # The message that is displayed can be customized.
    #
    #   validate_type_of!( params[:ids], Array, :allow_nil => true, :message => 'Value {value} should be an array' )
    #
    # Configuration Options:
    # * <tt>:allow_nil</tt> - Skip the validation if the supplied value is nil
    # * <tt>:message</tt> - A custom error message.  {value} can be use to reference the value being validated.
    def validate_type_of!( value, type, caller_options = {} )
      raise( ValidationException, message( value, caller_options[:message] ) ) unless validate_type_of( value, type, caller_options ) 
    end

    # Validates whether the supplied value is numeric by converting it to a Float using Kernel.Float
    #
    #  validate_numericality_of( '1234' )
    #  validate_numericality_of( '', :allow_nil => true )
    #  validate_numericality_of( '123.09', :integer_only => true )
    #  validate_numericality_of( '123.09', :less_than => 124 )
    #
    # Configuration Options:
    # * <tt>:only_integer</tt> - Specifies whether the value has to be an integer, e.g. an integral value (default is +false+).
    # * <tt>:allow_nil</tt> - Skip validation if supplied value is +nil+ (default is +false+). Note that empty strings are converted to +nil+.
    # * <tt>:greater_than</tt> - Specifies the supplied value must be greater than the option value.
    # * <tt>:greater_than_or_equal_to</tt> - Specifies the supplied value must be greater than or equal the option value.
    # * <tt>:equal_to</tt> - Specifies the supplied value must be equal to the option value.
    # * <tt>:less_than</tt> - Specifies the supplied value must be less than the option value.
    # * <tt>:less_than_or_equal_to</tt> - Specifies the supplied value must be less than or equal the option value.
    # * <tt>:odd</tt> - Specifies the supplied value must be an odd number.
    # * <tt>:even</tt> - Specifies the supplied value must be an even number.
    def validate_numericality_of( value, caller_options = {} )
      options = @@options.merge( caller_options )

      if options[:only_integer]
        cardinality = options[:allow_nil] ? '*' : '+'
        return Regexp.new( "^\\d#{cardinality}$" ).match( value )
      end

      return value.to_f < options[:less_than].to_f if options[:less_than]

      return value.to_f <= options[:less_than_or_equal_to].to_f if options[:less_than_or_equal_to]

      return value.to_f > options[:greater_than].to_f if options[:greater_than]

      return value.to_f >= options[:greater_than_or_equal_to].to_f if options[:greater_than_or_equal_to]

      return value.to_f == options[:equal_to].to_f if options[:equal_to]

      value = nil if value.is_a?( String ) && value.empty?

      if value.nil?
        return true if options[:allow_nil]
        return false
      end

      if options[:even]
        return true if value.to_f % 2 == 0
        return false
      end

      if options[:odd]
        return true if value.to_f % 2 > 0
        return false
      end

      begin
        Kernel.Float( value )
      rescue ArgumentError
        return false
      else
        return true
      end
    end

    def validate_numericality_of!( value, caller_options = {} )
      raise( ValidationException, message( value, caller_options[:message] ) ) unless validate_numericality_of( value, caller_options )
    end

    def validate_inclusion_of( value, collection, caller_options = {} )
      options = @@options.merge( caller_options )

      return false unless collection.is_a?( Array )

      return true if value.nil? and options[:allow_nil]

      return true if value.empty? and options[:allow_blank]

      return false if value.nil?

      if options[:ignore_case]
        value.downcase! if value.is_a?( String )
        return collection.map { |v| v.downcase if v.is_a?( String ) }.include?( value )
      else
        return collection.include?( value )
      end
    end

    def validate_inclusion_of!( value, collection, caller_options = {} )
      raise( ValidationException, message( value, caller_options[:message] ) ) unless validate_inclusion_of( value, collection, caller_options ) 
    end

# I wrote both of these methods, and before I got to testing them, I realized that I really didn't need them.
# I'm leaving them in just in case somebody else might need them at some point. Please do test before use. :^) .L
    # Validates the format of the value provided with a regular expression, also provided.
    #
    # validate_format_of( 'thingy', /^\w+$/ )
    # validate_format_of( 'thingy', /^\w+$/, :allow_nil = true )
    #
    # Configuration Options:
    # * <tt>:allow_nil</tt> - Skip validation if supplied value is +nil+ (default is +false+).
    def validate_format_of( value, regex, caller_options = {} )
      options = @@options.merge( caller_options )

      return options[:allow_nil] if value.nil?

      return true if regex.match( value.to_s ) rescue Exception

      return false
    end

    def validate_format_of!( value, regex, caller_options = {} )
      raise( ValidationException, message( value, caller_options[:message] ) ) unless validate_format_of( value, regex, caller_options )
    end

    private

    def message( value, message = nil )
      return message ? message.gsub( '{value}', value ) : "Invalid value: #{value}"
    end
  end
end
