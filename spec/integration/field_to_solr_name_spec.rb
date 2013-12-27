require 'spec_helper'

describe "An object with RDF backed attributes" do

  before do
    class TestOne < ActiveFedora::Base
      class MyMetadata < ActiveFedora::NtriplesRDFDatastream
        map_predicates do |map|
          map.title(in: RDF::DC) do |index|
            index.as :stored_searchable
          end
        end
      end
      has_metadata 'descMetadata', type: MyMetadata
      has_attributes :title, datastream: 'descMetadata'
    end
  end

  after do 
    Object.send(:remove_const, :TestOne)
  end

  it "should be able to grab the solr name" do
    expect(TestOne.defined_attributes[:title].primary_solr_name).to eq 'desc_metadata__title_tesim'
  end
end
