require 'solrizer/field_name_mapper'
require 'uri'
require 'rdf/rdfxml'
require 'rdf'
require 'active_fedora/rdf_xml_writer'

module ActiveFedora
  class RelsExtDatastream < Datastream
    
    include Solrizer::FieldNameMapper
    attr_accessor :model

    def add_mime_type
      self.mimeType= 'application/rdf+xml'
    end

    def serialize!
      self.content = to_rels_ext() if model.relationships_are_dirty
      model.relationships_are_dirty = false
    end
    

    def to_xml(fields_xml) 
      to_rels_ext() 
    end
      
    # Populate a RelsExtDatastream object based on the "datastream" content 
    # Assumes that the datastream contains RDF XML from a Fedora RELS-EXT datastream 
    # @param [ActiveFedora::MetadataDatastream] tmpl the Datastream object that you are populating
    # @param [String] the "rdf" node 
    def self.from_xml(xml, tmpl) 
      if (xml.nil?)
        ### maybe put the template here?
      else
        RDF::RDFXML::Reader.new(xml) do |reader|
          reader.each_statement do |statement|
            literal = statement.object.kind_of?(RDF::Literal)
            predicate = self.short_predicate(statement.predicate)
            object = literal ? statement.object.value : statement.object.to_str
            tmpl.model.add_relationship(predicate, object, literal)
          end
        end
        tmpl.model.relationships_are_dirty = false
        tmpl
      end
    end

    # Creates a RELS-EXT datastream for insertion into a Fedora Object
    def to_rels_ext()
      xml = ActiveFedora::RDFXMLWriter.buffer do |writer|
        writer.prefixes.merge! ActiveFedora::Predicates.predicate_namespaces
        model.relationships.each_statement do |statement|
          writer << statement
        end
      end
      xml
    end

    def self.short_predicate(predicate)
      if match = /^(#{Predicates.predicate_mappings.keys.join('|')})(.+)$/.match(predicate.to_str)
        namespace = match[1]
        predicate = match[2]
        pred = Predicates.predicate_mappings[namespace].invert[predicate]
        pred
      else
        raise "Unable to parse predicate: #{predicate}"
      end
    end
    
    
    # ** EXPERIMENTAL **
    # 
    # This is utilized by ActiveFedora::Base.load_instance_from_solr to load 
    # the relationships hash using the Solr document passed in instead of from the RELS-EXT datastream
    # in Fedora.  Utilizes solr_name method (provided by Solrizer::FieldNameMapper) to map solr key to
    # relationship predicate. 
    #
    # ====Warning
    #  Solr must be synchronized with RELS-EXT data in Fedora.
    def from_solr(solr_doc)
      profile_from_solr(solr_doc)
      #cycle through all possible predicates
      model.relationships_loaded = true
      Predicates.predicate_mappings.each_pair do |namespace,predicates|
        predicates.keys.each do |predicate|
          predicate_symbol = ActiveFedora::SolrService.solr_name(predicate, :symbol)
          value = (solr_doc[predicate_symbol].nil? ? solr_doc[predicate_symbol.to_s]: solr_doc[predicate_symbol]) 
          unless value.nil? 
            if value.is_a? Array
              value.each do |obj|
                model.add_relationship(predicate, obj)
              end
            else
              model.add_relationship(predicate, value)
            end
          end
        end
      end
      @load_from_solr = true
    end
  end
end
