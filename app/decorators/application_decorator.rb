class ApplicationDecorator < RDecorator::Base
  include ApplicationHelper
  
  def created_at( options={} )
    locale_datetime origin.created_at, options
  end
  
  def updated_at( options={} )
    locale_datetime origin.updated_at, options
  end
  
  protected
  
  def locale_datetime( v, options = {} )
    format = options[:format] || :default
    I18n.l( v, :format => format )
  end
  
  def string_with_linefeed( str )
    ERB::Util.html_escape( str ).gsub( "\n", "<br />" ).html_safe
  end
  
  def method_missing(method, *arg, &block)
    if origin.attribute_names.include?(method.to_s)
      attribute_with_format( method )
    else
      super
    end
  end
  
  def translate_constant_value( mod )
    n = mod.name.underscore.split('/').last
    v = origin.send( n )
    k = mod.constants.find do |key|
      mod.const_get(key) == v
    end
    k = k.downcase
    
    defaults = origin.class.lookup_ancestors.map do |klass|
      :"#{klass.model_name.i18n_key}.#{n}.#{k}"
    end
    defaults << :"#{origin.class.model_name.i18n_key}.#{n}.#{k}"
    defaults << k
    
    key = defaults.shift
    t = I18n.t( key, :default => defaults )
  end

  def value_with_format( value, key, options = {} )
    
    if origin.class.respond_to?(:i18n_scope)
      defaults = origin.class.lookup_ancestors.map do |klass|
         :"#{origin.class.i18n_scope}.format.models.#{klass.model_name.i18n_key}.#{key}"
      end
    else
      defaults = []
    end
    
    defaults << :"activerecord.format.models.#{origin.class.model_name.i18n_key}.#{key}"
    defaults << :"activerecord.format.#{key}"
    defaults << value.to_s
    #Rails.logger.debug "defaults: #{defaults}"
    
    k = defaults.shift

    options = {
      :default => defaults,
      :value => value
    }.merge( options )
    I18n.t( k, options )
  end
  
  def attribute_with_format( attribute, options = {} )
    value = (options[:value] ||= origin.send( attribute ))
    
    options = {
      :model => origin.class.model_name.human,
      :attribute => origin.class.human_attribute_name(attribute)
    }.merge( options )
    
    value_with_format( value, attribute, options )
  end
  
end