# Event tracking

At GitLab we encourage event tracking so we can iterate on and improve the project and user experience by running experiments and collecting analytics for features and feature variations. This is both to generally know engagement, as well as a way to approach A/B testing.

To enable the Product team to better understand user engagement, usage patterns, and other metrics that can potentially be improved on, we should attempt to add tracking where possible. To enable this, maintain consistency, and not adversely effect performance we have some basic tracking functionality exposed at both the frontend and backend layers that you can utilize while building features.

Todo: Document the process to define new tracking by integrating with the data team.
{: .alert .alert-danger}

## Enabling tracking

Snowplow can be enabled by navigating to:

- **Admin area > Settings > Integrations** in the UI.
- `admin/application_settings/integrations` in your browser.

The following configuration is required:

| Name          | Value                     |
| ------------- | ------------------------- |
| Collector     | `snowplow.trx.gitlab.net` |
| Site ID       | `gitlab`                  |
| Cookie domain | `.gitlab.com`             |

Now the implemented tracking events can be inspected locally by looking at the network panel of the browser's development tools.

## Tracking libraries

There's a couple libraries that we utilize for tracking. The first is Snowplow, and the second is Pendo.

## Snowplow

Snowplow is being used for event tracking. This allows the data team to define analytics and presentations of the event data in ways that may reveal details of user engagement that may not be fully understood or interactions where we can make improvements.

Event tracking can be implemented on either the frontend or the backend layers, and each can be approached slightly differently. 

In GitLab, many actions can be initiated via the web interface, but they can also be initiated via an API client (an iOS applications is a good example of this), or via `git` directly. Crucially, this means that tracking should be considered holistically for the new feature that's being implemented, or the existing feature that's being instrumented.

### Frontend tracking strategies

Generally speaking the frontend can track user actions and events, like clicking links/buttons, submitting forms, and other typically interface driven actions.

See [Frontend tracking strategies](frontend.md).

### Backend tracking strategies

From the backend, tracking will likely consist of things like the creation or deletion of records and other events that might be triggered from layers that aren't necessarily only available in the interface layer.

See [Backend tracking strategies](backend.md).

## Pendo

Session tracking is generally being handled by Pendo, which is a purely client library and is a relatively minor development concern.
