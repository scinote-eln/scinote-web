# frozen_string_literal: true

module Experiments
  class GenerateWorkflowImageService
    extend Service
    require 'graphviz'

    attr_reader :errors

    def initialize(experiment:)
      @exp = experiment
      graph_params = {
        type: :digraph,
        use: :neato,
        inputscale: 3,
        size: '2,2',
        pad: '0.4',
        ratio: 'fill',
        splines: true,
        center: true,
        pack: true,
        bgcolor: Constants::COLOR_CONCRETE,
        mode: 'ipsep'
      }
      @graph = GraphViz.new(:G, graph_params)
      @graph.node[color: Constants::COLOR_VOLCANO,
                  style: :filled,
                  fontcolor: Constants::COLOR_VOLCANO,
                  shape: 'circle',
                  fontname: 'Arial',
                  fontsize: '16.0']

      @graph.edge[color: Constants::COLOR_VOLCANO, penwidth: '3.0']
      @errors = []
    end

    def call
      draw_diagram
      save_file
      self
    end

    def succeed?
      @errors.none?
    end

    private

    def draw_diagram
      # Draw grouped modules
      subg = {}
      @exp.my_module_groups.each_with_index do |group, gindex|
        subgraph_id = "cluster-#{gindex}"
        subg[subgraph_id] = @graph.subgraph
        nodes = {}

        group.my_modules.workflow_ordered.each_with_index do |my_module, index|
          # draw nodes
          node = subg[subgraph_id].add_nodes(
            "#{subgraph_id}-#{index}",
            label: '',
            pos: "#{my_module.x / 10},-#{my_module.y / 10}!"
          )
          nodes[my_module.id] = node
        end

        # draw edges
        group.my_modules.workflow_ordered.each do |m|
          m.outputs.each do |output|
            parent_node = nodes[m.id]
            child_node = nodes[output.input_id]
            subg[subgraph_id].add_edges(parent_node, child_node)
          end
        end
      end

      # Draw orphan nodes
      @exp.my_modules.without_group.each do |my_module|
        @graph.subgraph.add_nodes(
          "Orphan-#{my_module.id}",
          label: '',
          pos: "#{my_module.x / 10},-#{my_module.y / 10}!"
        )
      end
    end

    def save_file
      file = Tempfile.open(%w(wimg .png), Rails.root.join('tmp'))
      begin
        @graph.output(png: file.path)
        file.rewind
        @exp.workflowimg.attach(io: file, filename: File.basename(file.path))
      ensure
        file.close
        file.unlink
      end
    end
  end
end
