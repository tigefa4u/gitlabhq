---
type: reference
---

# Directed Acyclic Graph

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/47063) in GitLab 12.2.

A [directed acyclic graph](https://www.techopedia.com/definition/5739/directed-acyclic-graph-dag) can be
used in the context of a CI/CD pipeline to build relationships between jobs such that
execution is performed in the quickest possible manner, regardless of stages that may
be set up. For example, you may have a specific tool or separate website that is built
as part of your main project: using a DAG, you can specify the relationship between
these jobs and GitLab will then execute the jobs as soon as possible instead of waiting
for each stage to complete.

Alternatively, consider a monorepo as follows:

| build | test | deploy |
| ----- | ---- | ------ |
| service_a | test_a | deploy_a |
| service_b | test_b | deploy_b |

Using a DAG, you can relate the `_a` jobs to each other separately from the `_b` jobs,
and even if service `a` takes a very long time to build, service `b` will not
wait for it and will finish as quickly as it can.

# Usage

Relationships are defined between jobs using the `needs:` keyword. Documentation
for how to do so can be found in our [pipeline configuration reference](https://docs.gitlab.com/ee/ci/yaml/#stage).

# Limitations

A directed acyclic graph is a complicated feature and as of the initial MVC there
are certain use cases that you may need to work around. We are tracking these in the epic
[gitlab-org#1716](https://gitlab.com/groups/gitlab-org/-/epics/1716), and they are also
documented with the usage link above.