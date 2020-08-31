# frozen_string_literal: true

module Experiments
  class GenerateWorkflowImageService
    extend Service
    require 'graphviz'

    attr_reader :errors

    def initialize(experiment_id:)
      @exp = Experiment.find experiment_id
      @graph = GraphViz.new(:G, type: :digraph, use: :neato)

      @graph[:size] = '4,4'
      @graph.node[color: Constants::COLOR_ALTO,
                  style: :filled,
                  fontcolor: Constants::COLOR_VOLCANO,
                  shape: 'circle',
                  fontname: 'Arial',
                  fontsize: '16.0']

      @graph.edge[color: Constants::COLOR_ALTO]
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
      # Draw orphan nodes
      @exp.my_modules.without_group.each do |my_module|
        @graph.subgraph(rank: 'same').add_nodes(
          "Orphan-#{my_module.id}",
          label: '',
          pos: "#{my_module.x / 10},-#{my_module.y / 10}!"
        )
      end

      # Draw grouped modules
      subg = {}
      @exp.my_module_groups.each_with_index do |group, gindex|
        subgraph_id = "cluster-#{gindex}"
        subg[subgraph_id] = @graph.subgraph(rank: 'same')
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
    end

    def save_file
      file = Tempfile.open(%w(wimg .png), Rails.root.join('tmp'))
      @graph.output(png: file.path)
      @exp.workflowimg.attach(io: file, filename: File.basename(file.path))
      file.close
      file.unlink
    end
  end
end
