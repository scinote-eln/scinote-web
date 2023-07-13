# frozen_string_literal: true

module Experiments
  class GenerateWorkflowImageService
    extend Service
    require 'graphviz'

    attr_reader :errors

    def initialize(experiment:)
      @exp = experiment
      @graph_params = {
        inputscale: 3,
        size: '2,2',
        pad: '0.4',
        ratio: 'fill',
        splines: true,
        center: true,
        pack: true,
        bgcolor: 'transparent'
      }
      @node_params = {
        color: Constants::COLOR_VOLCANO,
        style: :filled,
        fontcolor: Constants::COLOR_VOLCANO,
        shape: 'circle',
        fontname: 'Arial',
        fontsize: '16.0'
      }
      @edge_params = {
        color: Constants::COLOR_VOLCANO,
        penwidth: '3.0'
      }

      @graph = Graphviz::Graph.new('G', **@graph_params)
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
      @exp.my_module_groups.each_with_index do |group, gindex|
        subgraph_id = "cluster-#{gindex}"
        nodes = {}

        group.my_modules.workflow_ordered.each_with_index do |my_module, index|
          # draw nodes
          node = @graph.add_node(
            "#{subgraph_id}-#{index}",
            **@node_params.merge(
              label: '',
              pos: "#{my_module.x / 10},-#{my_module.y / 10}!"
            )
          )
          nodes[my_module.id] = node
        end

        # draw edges
        group.my_modules.workflow_ordered.each do |m|
          m.outputs.each do |output|
            parent_node = nodes[m.id]
            child_node = nodes[output.input_id]
            parent_node.connect(child_node, @edge_params)
          end
        end
      end

      # Draw orphan nodes
      @exp.my_modules.without_group.each do |my_module|
        @graph.add_node(
          "Orphan-#{my_module.id}",
          **@node_params.merge(
            label: '',
            pos: "#{my_module.x / 10},-#{my_module.y / 10}!"
          )
        )
      end
    end

    def save_file
      file = Tempfile.open(%w(wimg .png), Rails.root.join('tmp'))
      begin
        Graphviz.output(@graph, path: file.path, format: 'png', dot: 'neato')
        file.rewind
        @exp.workflowimg.attach(io: file, filename: File.basename(file.path))
      ensure
        file.close
        file.unlink
      end
    end
  end
end
