---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Best practices for GitLab Duo Agent Platform
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Private beta

{{< /details >}}

{{< history >}}

- [Name changed](https://gitlab.com/gitlab-org/gitlab/-/issues/551382) from `Workflow` to `Agent Platform` in GitLab 18.2. 

{{< /history >}}

{{< alert type="warning" >}}

This feature is [a private beta](../../policy/development_stages_support.md) and is not intended for customer usage outside of initial design partners. We expect major changes to this feature.

{{< /alert >}}

When you use the GitLab Duo Agent Platform in the IDE, follow these best practices to get the most value from the software development flow.

## Create focused prompts

A prompt is the text input that you give to the Agent Platform. To create an effective prompt:

- Define a clear goal with measurable outcomes.
- Provide clear context by including relevant files, merge requests, or issues.
  For information about the types of context the Agent Platform understands, see
  [context](_index.md#the-context-the-agent-platform-is-aware-of).
- Provide examples of expected changes.
- Include or link to any technical requirements or rules.

Example prompt:

```plaintext
Scan all Vue.js components in the 'src/components' directory. Add appropriate ARIA attributes
to improve accessibility. Focus on buttons, forms, and navigation elements.
Ensure changes maintain existing functionality.
```

## Review the plan

After you enter your prompt, the Agent Platform generates a plan containing tasks. You can pause and restart while it creates and works through its plan.

During this process:

- Confirm all target files are correctly identified.
- Verify proposed changes align with requirements.
- Check for any missing dependencies or integration points.
- Pause the workflow and adjust if needed.

## Check proposed changes

As the Agent Platform works through its plan, it stages corresponding changes to the files in your project. The changes might include new or modified files.

Before committing the changes:

1. Check that the Agent Platform:

   - Targeted the correct files.
   - Made appropriate changes.
   - Followed the requirements and rules from your prompt.

1. Look for patterns in what it's missing or misinterpreting. Use that data to refine your prompt. Common errors include:

   - The incorrect solution. We are continuing to work on the accuracy of overall generated content. However, suggestions might be:
     - Irrelevant.
     - Incomplete.
     - Results in failed pipelines.
     - Potentially insecure.
     - Offensive or insensitive.
   - Adds code in the wrong location.
   - Includes code changes that can't be used by other parts of the system.

## Iterate and improve

When the Agent Platform does not produce the expected results:

- Document the specific areas that need improvement.
- Break complex goals into smaller workflows.
- Add examples of correct and incorrect implementations.
- Refine prompts to address gaps.

For example, refine your prompts from the general to the specific:

General:

```plaintext
Add ARIA attributes to improve accessibility.
```

Specific:

```plaintext
Add aria-label attributes to buttons without text content.
Use the button's function for the label value.
Required format: aria-label="Action description"
```
