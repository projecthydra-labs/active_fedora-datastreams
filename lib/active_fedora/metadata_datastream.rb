module ActiveFedora
  #this class represents a MetadataDatastream, a special case of ActiveFedora::Datastream
  class MetadataDatastream < Datastream
    
    include ActiveFedora::MetadataDatastreamHelper

    self.xml_model = ActiveFedora::MetadataDatastream
    
    # def to_solr(solr_doc = Solr::Document.new) # :nodoc:
    #   fields.each do |field_key, field_info|
    #     if field_info.has_key?(:values) && !field_info[:values].nil?
    #       field_symbol = generate_solr_symbol(field_key, field_info[:type])
    #       field_info[:values].each do |val|             
    #         solr_doc << Solr::Field.new(field_symbol => val)
    #       end
    #     end
    #   end
    # 
    #   return solr_doc
    # end
    # 
    # def to_xml(xml = REXML::Document.new("<fields />")) #:nodoc:
    #   fields.each_pair do |field,field_info|
    #     el = REXML::Element.new("#{field.to_s}")
    #       if field_info[:element_attrs]
    #         field_info[:element_attrs].each{|k,v| el.add_attribute(k.to_s, v.to_s)}
    #       end
    #     field_info[:values].each do |val|
    #       el = el.clone
    #       el.text = val.to_s
    #       if xml.class == REXML::Document
    #         xml.root.elements.add(el)
    #       else
    #         xml.add(el)
    #       end
    #     end
    #   end
    #   return xml.to_s
    # end
    # 
    # @tmpl ActiveFedora::MetadataDatastream
    # @node Nokogiri::XML::Node
    def self.from_xml(tmpl, node) # :nodoc:
      node.xpath("./foxml:datastreamVersion[last()]/foxml:xmlContent/fields/node()").each do |f|
          tmpl.send("#{f.name}_append", f.text) unless f.class == Nokogiri::XML::Text
      end
      tmpl.send(:dirty=, false)
      tmpl
    end
    
    # This method generates the various accessor and mutator methods on self for the datastream metadata attributes.
    # each field will have the 3 magic methods:
    #   name_values=(arg) 
    #   name_values 
    #   name_append(arg)
    #
    #
    # Calling any of the generated methods marks self as dirty.
    #
    # 'tupe' is a datatype, currently :string, :text and :date are supported.
    #
    # opts is an options hash, which  will affect the generation of the xml representation of this datastream.
    #
    # Currently supported modifiers: 
    # For +QualifiedDublinCorDatastreams+:
    #   :element_attrs =>{:foo=>:bar} -  hash of xml element attributes
    #   :xml_node => :nodename  - The xml node to be used to represent this object (in dcterms namespace)
    #   :encoding=>foo, or encodings_scheme  - causes an xsi:type attribute to be set to 'foo'
    #   :multiple=>true -  mark this field as a multivalue field (on by default)
    #
    #At some point, these modifiers will be ported up to work for any +ActiveFedora::MetadataDatastream+.
    #
    #There is quite a good example of this class in use in spec/examples/oral_history.rb
    #
    #!! Careful: If you declare two fields that correspond to the same xml node without any qualifiers to differentiate them, 
    #you will end up replicating the values in the underlying datastream, resulting in mysterious dubling, quadrupling, etc. 
    #whenever you edit the field's values.
    def field(name, tupe, opts={})
      @fields[name.to_s.to_sym]={:type=>tupe, :values=>[]}.merge(opts)
      eval <<-EOS
        def #{name}_values=(arg)
          @fields["#{name.to_s}".to_sym][:values]=[arg].flatten
          self.dirty=true
        end
        def #{name}_values
          @fields["#{name}".to_sym][:values]
        end
        def #{name}_append(arg)
          @fields["#{name}".to_sym][:values] << arg
          self.dirty =true
        end
      EOS
    end

  end

end
