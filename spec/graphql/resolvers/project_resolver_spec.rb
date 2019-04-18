require 'spec_helper'

describe Resolvers::ProjectResolver do
  include GraphqlHelpers

  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }

  let_it_be(:other_project) { create(:project) }

  describe '#resolve' do
    it 'batch-resolves projects by full path' do
      paths = [project1.full_path, project2.full_path]

      result = batch(max_queries: 1) do
        paths.map { |path| resolve_project(path) }
      end

      expect(result).to contain_exactly(project1, project2)
    end

    it 'resolves an unknown full_path to nil' do
      result = batch { resolve_project('unknown/project') }

      expect(result).to be_nil
    end
  end

  def resolve_project(full_path)
    resolve(described_class, args: { full_path: full_path })
  end
end
