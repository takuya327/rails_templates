# coding: utf-8

class ActionView::Helpers::FormBuilder

  # 日本語日付選択
  def date_select_jp(method, options={}, html_options={})
    options[:use_month_numbers] = true unless options[:use_month_numbers]
    t = date_select(method, options, html_options)
    if options[:discard_day]
      t.sub(/<\/select>(.+?)<\/select>/m, "</select>年\\1</select>月").html_safe
    else
      t.sub(/<\/select>(.+?)<\/select>(.+?)<\/select>/m, "</select>年\\1</select>月\\2</select>日").html_safe
    end
  end
  
end

module ActionDispatch::Routing::UrlFor
  
  def full_url_for(options={})
    case options
    when Hash
      url_for({
        :only_path => false,
        :protocol => Setting.service.protocol,
        :host => Setting.service.host,
        :port => Setting.service['port']
      }.merge(options))
    when String
      URI::Generic.build(
        :scheme => Setting.service.protocol.sub("://",""),
        :host => Setting.service.host,
        :port => Setting.service['port'],
        :path => options
      ).to_s
    else
      URI::Generic.build(
        :scheme => Setting.service.protocol.sub("://",""),
        :host => Setting.service.host,
        :port => Setting.service['port'],
        :path => polymorphic_path(options)
      ).to_s
    end
  end
  
end

class ActiveRecord::Base
  def to_id
    self.id
  end
end

class String
  def to_id
    self.to_i
  end
end

class Integer
  def to_id
    self
  end
end

class Time
  def self.rand( from = 0.0, to = Time.now )
    Time.at(from.to_f + Kernel.rand * (to.to_f - from.to_f))
  end
end

class NilClass
  def expand_cache_key(key, namespace = nil)
    ActiveSupport::Cache.expand_cache_key( key, namespace )
  end
end

module Faker
  class Date
    def self.birthday( from = Time.now.years_ago(80), to = Time.now.years_ago(2) )
      Time.rand( from, to ).to_date
    end
  end
end
