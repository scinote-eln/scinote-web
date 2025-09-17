# frozen_string_literal: true

require 'rails_helper'

SEARCH_SPECIAL_CHARACTER_TEST_NAMES =  %w(
  NameWithNoSpecialCharacters
  NameWith_Underscore
  NameWith@At
  NameWith.Dot
  NameWith-Minus
  NameWith+Plus
  NameWith&Ampersand
  NameWith;Semicolon
  NameWith:Colon
  NameWith,Comma
  NameWith$Dollar
  NameWith/Slash
  NameWith=Equals
  NameWith~Tilde
  NameWith^Caret
  NameWith°Degree
  NameWith`Backtick
  NameWith"DoubleQuote
  NameWith'SingleQuote
  NameWith*Asterisk
  NameWith?QuestionMark
  NameWith%Percent
  NameWith\Backslash
  NameWith[SquareBracket]
  NameWith{CurlyBracket}
  NameWith(Parenthesis)
  NameWith|Pipe
  NameWith!Exclamation
).freeze

describe SearchableModel, type: :concern do
  let!(:user) { create :user }
  let!(:team) { create :team, created_by: user }

  let!(:projects) do
    SEARCH_SPECIAL_CHARACTER_TEST_NAMES.map do |name|
      Project.create!(name: name, team: user.teams.first, created_by: user)
    end
  end

  it '#where_attributes_like_boolean finds all projects by name' do
    SEARCH_SPECIAL_CHARACTER_TEST_NAMES.each do |name|
      expect(Project.where_attributes_like_boolean(['name'], "#{name} OR something")&.first&.name).to eq name
      puts "Found #{name}"
    end
  end

  it '#where_attributes_like_boolean finds all projects by exact name' do
    SEARCH_SPECIAL_CHARACTER_TEST_NAMES.filter { |n| n != 'NameWith"DoubleQuote' }.each do |name|
      expect(Project.where_attributes_like_boolean(['name'], "\"#{name}\"")&.first&.name).to eq name
      expect(Project.where_attributes_like_boolean(['name'], "\"#{name} not exact\"").count).to eq 0
      puts "Found #{name}"
    end
  end

  it '#where_attributes_like finds all projects by name ' do
    SEARCH_SPECIAL_CHARACTER_TEST_NAMES.each do |name|
      expect(Project.where_attributes_like(['name'], name)&.first&.name).to eq name
      puts "Found #{name}"
    end
  end
end
