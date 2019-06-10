<script>
import { GlSkeletonLoading } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoading,
  },
};
</script>

<template>
  <ul class="content-list issues-list issuable-list js-issues-loading">
    <li v-for="n in 8" :key="n" class="issue">
      <gl-skeleton-loading />
    </li>
  </ul>
</template>
