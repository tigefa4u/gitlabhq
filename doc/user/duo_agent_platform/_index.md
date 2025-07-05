---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platform
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Private beta
- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14153) in GitLab 17.4 [with a flag](../../administration/feature_flags/_index.md) named `duo_workflow`. Enabled for GitLab team members only. This feature is a [private beta](../../policy/development_stages_support.md).
- [Name changed](https://gitlab.com/gitlab-org/gitlab/-/issues/551382) from `Workflow` to `Agent Platform` in GitLab 18.2. 

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for internal GitLab team members for testing, but not ready for production use.

{{< /alert >}}

{{< alert type="warning" >}}

This feature is [a private beta](../../policy/development_stages_support.md) and is not intended for customer usage outside of initial design partners. We expect major changes to this feature.

{{< /alert >}}

{{< alert type="disclaimer" />}}

With the GitLab Duo Agent Platform, multiple AI agents can work in parallel, helping you create code,
research results, and perform tasks simultaneously.
The agents have full context across your entire software development lifecycle.

Use the Agent Platform to work on large problems, like understanding a codebase or
generating an implementation plan. For more focused pieces of work, like generating
or understanding specific code, use [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md) instead.

For more details, [view this blog post](https://about.gitlab.com/blog/gitlab-duo-agent-platform-what-is-next-for-intelligent-devsecops/).

The Agent Platform is currently available in the VS Code IDE.

- It runs in your IDE so that you do not have to switch contexts or tools.
- It creates and works through a plan, in response to your prompt.
- It stages proposed changes in your project's repository.
  You control when to accept, modify, or reject the suggestions.
- Understands the context of your project structure, codebase, and history.
  You can also add your own context, such as relevant GitLab issues or merge requests.

For a click-through demo, see [GitLab Duo Agent Platform](https://gitlab.navattic.com/duo-workflow).
<!-- Demo published on 2025-03-18 -->

For an overview, watch <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Enhancing your quality assurance with GitLab Duo Agent Platform](https://youtu.be/Tuj7TgqY81Q?si=IbxaKv7IhAHYnHkN). <!-- Video published on 2025-03-20-->

## Prerequisites

Before you can use the Agent Platform in VS Code, you must:

- [Install Visual Studio Code](https://code.visualstudio.com/download) (VS Code).
- [Set up the GitLab Workflow extension for VS Code](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#setup). Minimum version 5.16.0.
- Have an account on GitLab.com.
- Have a project that meets the following requirements:
  - The project is on GitLab.com.
  - You have at least the Developer role.
  - The project belongs to a [group namespace](../namespace/_index.md) with an Ultimate subscription.
  - [Beta and experimental features must be turned on](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
  - [GitLab Duo must be turned on](../gitlab_duo/turn_on_off.md).
- [Successfully connect to your repository](#connect-to-your-repository).
- [Ensure an HTTP/2 connection to the backend service is possible](troubleshooting.md#network-issues).

{{< alert type="note" >}}

Though not recommended, you can [set up the Agent Platform in a Docker container](docker_set_up.md).
You do not need to use Docker to run the Agent Platform.

{{< /alert >}}

## Connect to your repository

To use the Agent Platform in VS Code, ensure your repository is properly connected.

1. In VS Code, on the top menu, select **Terminal > New Terminal**.
1. Clone your repository: `git clone <repository>`.
1. Change to the directory where your repository was cloned and check out your branch: `git checkout <branch_name>`.
1. Ensure your project is selected:
   1. On the left sidebar, select **GitLab Workflow** ({{< icon name="tanuki" >}}).
   1. Select the project name. If you have multiple projects, select the one you want to work with.
1. In the terminal, ensure your repository is configured with a remote: `git remote -v`. The results should look similar to:

   ```plaintext
   origin  git@gitlab.com:gitlab-org/gitlab.git (fetch)
   origin  git@gitlab.com:gitlab-org/gitlab.git (push)
   ```

   If no remote is defined, or you have multiple remotes:

   1. On the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
   1. On the **Source Control** label, right-click and select **Repositories**.
   1. Next to your repository, select the ellipsis ({{< icon name=ellipsis_h >}}), then **Remote > Add Remote**.
   1. Select **Add remote from GitLab**.
   1. Choose a remote.

Now you can use the Agent Platform to help solve your coding tasks.

## Use the Agent Platform in VS Code

The software development flow is one of many possible flows in the Agent Platform.

To use the software development flow:

1. On the left sidebar, select **GitLab Duo Workflow** ({{< icon name="pencil" >}}).
1. In the text box, specify a code task in detail.
   - For assistance writing your prompt, see [use case examples](use_cases.md) and [best practices](best_practices.md).
   - The Agent Platform is aware of all files available to Git in the project branch.
   - You can also give the Agent Platform [additional context](#the-context-the-agent-platform-is-aware-of).
   - The Agent Platform cannot access external sources or the web.
1. Select **Start**.

After you describe your task, a plan is generated and executed.
You can pause or ask it to adjust the plan.

For more information about how to interact with the Agent Platform, see [best practices](best_practices.md).

## The context the Agent Platform is aware of

When you ask for help with a task in the Agent Platform, it will refer to files available to Git in the current branch of the project in your VS Code workspace.

You can ask about other projects, but they must meet the [prerequisites](#prerequisites).

You can also provide it with additional context.

| Area                    | Enter      | Examples |
|-------------------------|------------------------|----------|
| Local files             | The file with path. |• Summarize the file `src/main.js`<br>• Review the code in `app/models/`<br>• List all JavaScript files in the project |
| Epics                   | Either:<br>• The URL of the group or epic. <br>• The epic ID and the name of the group the epic is in. | Examples:<br>• List all epics in `https://gitlab.com/groups/namespace/group`<br>• Summarize the epic: `https://gitlab.com/groups/namespace/group/-/epics/42`<br>• `Summarize epic 42 in group namespace/group` |
| Issues                  | Either:<br>• The URL of the project or issue. <br>• The issue ID in the current or another project. | Examples:<br>• List all issues in the project at `https://gitlab.com/namespace/project`<br>• Summarize the issue at `https://gitlab.com/namespace/project/-/issues/103`<br>• Review the comment with ID `42` in `https://gitlab.com/namespace/project/-/issues/103`<br>• List all comments on the issue at `https://gitlab.com/namespace/project/-/issues/103`<br>• Summarize issue `103` in this project |
| Merge requests          | Either:<br>• The URL of the merge request. <br>• The merge request ID in the current or another project. |• Summarize `https://gitlab.com/namespace/project/-/merge_requests/103`<br>• Review the diffs in `https://gitlab.com/namespace/project/-/merge_requests/103`<br>• Summarize the comments on `https://gitlab.com/namespace/project/-/merge_requests/103`<br>• Summarize merge request `103` in this project |
| Merge request pipelines | The merge request ID in the current or another project. |• Review the failures in merge request `12345`<br>• Can you identify the cause of the error in the merge request `54321` in project `gitlab-org/gitlab-qa` <br>• Suggest a solution to the pipeline failure in `https://gitlab.com/namespace/project/-/merge_requests/54321` |

The Agent Platform also has access to the GitLab [Search API](../../api/search.md) to find related issues or merge requests.

## Supported languages

The Agent Platform officially supports the following languages:

- CSS
- Go
- HTML
- Java
- JavaScript
- Markdown
- Python
- Ruby
- TypeScript

## APIs that the Agent Platform has access to

To create solutions and understand the context of the problem,
the Agent Platform accesses several GitLab APIs.

Specifically, an OAuth token with the `ai_workflows` scope has access
to the following APIs:

- [Projects API](../../api/projects.md)
- [Search API](../../api/search.md)
- [CI Pipelines API](../../api/pipelines.md)
- [CI Jobs API](../../api/jobs.md)
- [Merge Requests API](../../api/merge_requests.md)
- [Epics API](../../api/epics.md)
- [Issues API](../../api/issues.md)
- [Notes API](../../api/notes.md)
- [Usage Data API](../../api/usage_data.md)

## Audit log

An audit event is created for each API request done by the Agent Platform.
On your GitLab Self-Managed instance, you can view these events on the
[instance audit events](../../administration/compliance/audit_event_reports.md#instance-audit-events) page.

## Give feedback

The Agent Platform is a private beta and your feedback is crucial to improve it for you and others.
To report issues or suggest improvements,
[complete this survey](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu).

## Related topics

- [Use GitLab Duo Agent Platform to improve application quality assurance](https://about.gitlab.com/blog/2025/04/10/use-gitlab-duo-workflow-to-improve-application-quality-assurance/)
