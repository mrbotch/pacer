require 'spec_helper'

Run.tg(:read_only) do
  context Pacer::Core::Graph::VerticesRoute do
    use_pacer_graphml_data(:read_only)

    describe '#out_e' do
      it { graph.v.out_e.should be_an_edges_route }
      it { graph.v.out_e(:label).should be_a(Pacer::Route) }
      it { graph.v.out_e(:label) { |x| true }.should be_a(Pacer::Route) }
      it { graph.v.out_e { |x| true }.should be_a(Pacer::Route) }

      it { Set[*graph.v.out_e].should == Set[*graph.edges] }

      it { graph.v.out_e.count.should >= 1 }

      specify 'with label filter should work with path generation' do
        r = graph.v.out_e.in_v.in_e { |e| e.label == 'wrote' }.out_v
        paths = r.paths
        paths.first.should_not be_nil
        graph.v.out_e.in_v.in_e(:wrote).out_v.paths.collect(&:to_a).should == paths.collect(&:to_a)
      end
    end
  end
end

Run.tg do
  use_pacer_graphml_data

  context Pacer::Core::Graph::VerticesRoute do
    describe :add_edges_to do
      before do
        setup_data
      end

      let(:pangloss) { graph.v(:name => 'pangloss') }
      let(:pacer) { graph.v(:name => 'pacer') }

      context '1 to 1' do
        before do
          @result = pangloss.add_edges_to(:likes, pacer, :pros => "it's fast", :cons => nil)
        end

        subject { @result.first }

        it { should_not be_nil }
        its(:out_vertex) { should == pangloss.first }
        its(:in_vertex) { should == pacer.first }
        its(:label) { should == 'likes' }

        it 'should store properties' do
          subject[:pros].should == "it's fast"
        end

        it 'should not add properties with null values' do
          subject.getPropertyKeys.should_not include('cons')
        end
      end

      context 'many to many' do
        let(:people) { graph.v(:type => 'person') }
        let(:projects) { graph.v :type => 'project' }

        subject { people.add_edges_to(:uses, projects) }

        it { should be_a(Pacer::Core::Route) }
        its(:element_type) { should == graph.element_type(:edge) }
        its(:count) { should == 8 }
        its('back.element_type') { should == Object }
        its('back.count') { should == 8 }

        specify 'all edges in rasge should exist' do
          subject.each do |edge|
            edge.should_not be_nil
            edge.label.should == 'uses'
          end
        end
      end

      context 'edge cases' do
        it 'should do nothing if there are no source vertices' do
          result = graph.v(:name => 'no match').add_edges_to(:likes, pacer, :pros => "it's fast", :cons => nil)
          result.should be_nil
        end

        it 'should do nothing if there are no target vertices' do
          result = pangloss.add_edges_to(:likes, graph.v(:name => 'I hate everytihng'))
          result.should be_nil
        end

        it 'should associate to a single element' do
          result = pangloss.add_edges_to(:likes, pacer.first)
          edge = result.first
          edge.should_not be_nil
        end

        it 'should do nothing if target is nil' do
          result = pangloss.add_edges_to(:likes, nil)
          result.should be_nil
        end
      end
    end
  end
end
