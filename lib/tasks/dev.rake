task dev: ["dev:setup"]

namespace :dev do
  desc "GitLab | Setup developer environment (db, fixtures)"
  task setup: :environment do
    ENV['force'] = 'yes'
    Rake::Task["gitlab:setup"].invoke
    Rake::Task["gitlab:shell:setup"].invoke
  end

  desc "GitLab | Eager load application"
  task load: :environment do
    Rails.application.eager_load!
  end

  desc "GitLab | Create many test groups and projects"
  task :populate, [:username, :prefix, :group_start, :group_end, :projects_per_group] => :environment do |task, args|
    user = User.find_by!(username: args.username || "root")
    prefix = args.prefix || "test-1"
    group_start = (args.group_start || 1).to_i
    group_end = (args.group_end || 5).to_i
    projects_per_group = (args.projects_per_group || 100).to_i

    ActiveRecord::Base.logger = nil

    group_start.upto(group_end).each do |gid|
      group_name = "#{prefix}-group-#{gid}"

      ActiveRecord::Base.transaction do
        group = Group.create!(path: group_name, name: group_name, owner: user)
        print "Group #{gid}: "

        1.upto(projects_per_group).each do |pid|
          project_name = "project-#{pid}"

          project = Projects::CreateService.new(
            user,
            name: project_name, path: project_name, namespace_id: group.id
          ).execute

          if project.errors.any?
           raise "Failed: #{gid}.#{pid}:\n\t#{project.errors.full_messages.join("\n\t")}"
           end

           print "." if pid%10==0
        end

        print "\n"
      end
    end
  end
end
