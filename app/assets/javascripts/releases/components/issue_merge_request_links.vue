<script>
import { s__, sprintf } from '~/locale';
import _ from 'underscore';

export default {
  name: 'IssueMergeRequestLinks',
  props: {
    milestone: {
      type: Object,
      required: true,
    },
    issuesUrl: {
      type: String,
      required: true,
    },
    mergeRequestsUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    queryParam() {
      return `milestone_title=${encodeURIComponent(_.escape(this.milestone.title))}`;
    },
    linkText() {
      const linkAttrs = 'target="_blank" rel="noopener noreferrer"';

      return sprintf(
        s__(
          'Releases|View %{issuesLinkStart}Issues%{linkEnd} or %{mrsLinkStart}Merge Requests%{linkEnd} in this release',
        ),
        {
          issuesLinkStart: `<a href="${_.escape(this.issuesUrl)}&${this.queryParam}" ${linkAttrs}>`,
          mrsLinkStart: `<a href="${_.escape(this.mergeRequestsUrl)}&${
            this.queryParam
          }" ${linkAttrs}>`,
          linkEnd: '</a>',
        },
        false,
      );
    },
  },
};
</script>
<template>
  <div v-html="linkText"></div>
</template>
