<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlLoadingIcon,
  },
  computed: {
    ...mapState(['isLoading']),
    ...mapGetters(['visibleStatistics']),
  },
  methods: {
    ...mapActions(['fetchStatistics']),
  },
  mounted() {
    this.fetchStatistics();
  },
};
</script>

<template>
  <div class="js-admin-statistics info-well">
    <div class="well-segment admin-well admin-well-statistics">
      <h4>{{ __('Statistics') }}</h4>
      <gl-loading-icon v-if="isLoading" size="md" class="my-3" />
      <template v-else>
        <p v-for="statistic in visibleStatistics" :key="statistic.key">
          {{ statistic.label }}
          <span class="light float-right">{{ statistic.value }}</span>
        </p>
      </template>
    </div>
  </div>
</template>
