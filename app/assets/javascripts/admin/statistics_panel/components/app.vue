<script>
import { mapState, mapGetters, mapActions } from 'vuex';

export default {
  computed: {
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
  <div class="well-segment admin-well admin-well-statistics">
    <h4>{{ __('Statistics') }}</h4>
    <p v-for="statistic in visibleStatistics" :key="statistic.key">
      {{ statistic.label }}
      <span class="light float-right">{{ statistic.value }}</span>
    </p>
  </div>
</template>
