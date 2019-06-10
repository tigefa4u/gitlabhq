<script>
import { GlEmptyState } from '@gitlab/ui';
import { ISSUE_STATES } from '../constants';

export default {
  components: {
    GlEmptyState,
  },
  props: {
    hasFilters: {
      type: Boolean,
      required: true,
    },
    state: {
      type: String,
      required: true,
    },
    buttonPath: {
      type: String,
      required: true,
    },
    loadingDisabled: {
      type: Boolean,
      required: true,
    },
    svgImagePath: {
      type: String,
      required: true,
    },
    svgLoadingDisabledImagePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      ISSUE_STATES,
    };
  },
};
</script>

<template>
  <gl-empty-state
    v-if="loadingDisabled"
    :title="__('Please select at least one filter to see results')"
    :svg-path="svgLoadingDisabledImagePath"
  />
  <gl-empty-state
    v-else-if="hasFilters"
    :title="__('Sorry, your filter produced no results')"
    :description="__('To widen your search, change or remove filters above')"
    :svg-path="svgImagePath"
  />
  <gl-empty-state
    v-else-if="state === ISSUE_STATES.OPENED"
    :title="__('There are no open issues')"
    :description="__('To keep this project going, create a new issue')"
    :primary-button-link="buttonPath"
    :primary-button-text="__('New issue')"
    :svg-path="svgImagePath"
  />
  <gl-empty-state
    v-else-if="state === ISSUE_STATES.CLOSED"
    :title="__('There are no closed issues')"
    :svg-path="svgImagePath"
  />
  <gl-empty-state
    v-else
    :title="__('There are no issues to show')"
    :description="
      __(
        'The Issue Tracker is the place to add things that need to be improved or solved in a project. You can register or sign in to create issues for this project.',
      )
    "
    :svg-path="svgImagePath"
  />
</template>
