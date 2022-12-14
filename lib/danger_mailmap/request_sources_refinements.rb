# frozen_string_literal: true

require 'danger'

module DangerMailmap
  # Collection of refinements of classes in {Danger::RequestSources}.
  module RequestSourcesRefinements
    refine Danger::RequestSources::BitbucketServer do
      def base_branch
        pr_json[:toRef][:id].sub('refs/heads/', '')
      end

      def head_branch
        pr_json[:fromRef][:id].sub('refs/heads/', '')
      end
    end

    refine Danger::RequestSources::GitHub do
      def base_branch
        pr_json['base']['ref']
      end

      def head_branch
        pr_json['head']['ref']
      end
    end

    refine Danger::RequestSources::VSTS do
      def base_branch
        pr_json[:targetRefName].sub('refs/heads/', '')
      end

      def head_branch
        pr_json[:sourceRefName].sub('refs/heads/', '')
      end
    end

    refine Danger::RequestSources::GitLab do
      def base_branch
        mr_json.source_branch
      end

      def head_branch
        mr_json.target_branch
      end
    end

    refine Danger::RequestSources::BitbucketCloud do
      def base_branch
        pr_json[:destination][:branch][:name]
      end

      def head_branch
        pr_json[:source][:branch][:name]
      end
    end

    refine Danger::RequestSources::LocalOnly do
      def base_branch
        commit = ci_source.base_commit
        scm.exec("rev-parse --quiet --verify #{commit}").empty? ? nil : commit
      end

      def head_branch
        commit = ci_source.head_commit
        scm.exec("rev-parse --quiet --verify #{commit}").empty? ? nil : commit
      end
    end
  end
end
