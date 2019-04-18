# Frontend FAQ

## Rules of Frontend FAQ

1. **You talk about Frontend FAQ.**
   Please share links to it whenever applicable, so more eyes catch when content
   gets outdated.
2. **Keep it short and simple.**
   Whenever an answer needs more than two sentences it does not belong here.
3. **Provide background when possible.**
   Linking to relevant source code, issue / epic, or other documentation helps
   to understand the answer.
4. **If you see something, do something.**
   Please remove or update any content that is outdated as soon as you see it.

## FAQ

### How do I find the Rails route for a page?

The easiest way is to type the following in the browser while on the page in
question:

```javascript
document.body.dataset.page
```

Find here the [source code setting the attribute](https://gitlab.com/gitlab-org/gitlab-ce/blob/cc5095edfce2b4d4083a4fb1cdc7c0a1898b9921/app/views/layouts/application.html.haml#L4).

### I am getting an unrelated / strange failure in my merge request. How did that happen?

Please check if there is already [an issue describing the problem](https://gitlab.com/groups/gitlab-org/-/issues?state=all&label_name[]=master%3Abroken) and otherwise refer to our [documentation about broken master](https://about.gitlab.com/handbook/engineering/workflow/#broken-master).
If you are still unsure how to proceed, feel free to raise this in the `#development` or `#frontend` Slack channel.