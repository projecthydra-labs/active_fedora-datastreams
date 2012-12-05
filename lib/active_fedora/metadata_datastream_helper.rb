require 'solrizer/field_name_mapper'

module ActiveFedora::MetadataDatastreamHelper 
  
  attr_accessor :fields, :xml_loaded
  
  module ClassMethods
    
    #get the Class's field list
    def fields
      @@classFields
    end
    
  end
  
  def self.included(klass)
    klass.extend(ClassMethods)
    klass.send(:include, Solrizer::FieldNameMapper)
  end

  def ensure_xml_loaded
    return if xml_loaded 
    self.xml_loaded = true
    if new?
      ## Load up the template
      self.class.from_xml nil, self
    else
      self.class.from_xml content, self
    end
  end
  
  def serialize! # :nodoc:
    if changed?
      return unless xml_loaded or new?
      self.content = self.to_xml 
    end
  end

end
