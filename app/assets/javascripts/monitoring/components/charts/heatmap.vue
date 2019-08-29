<script>
import { GlHeatmap } from '@gitlab/ui/dist/charts';
import { debounceByAnimationFrame } from '~/lib/utils/common_utils';
import { chartHeight } from '../../constants';

let debouncedResize;

export default {
  components: {
    GlHeatmap,
  },
  props: {
    graphData: {
      type: Object,
      required: true,
    },
    containerWidth: {
      type: Number,
      required: true,
    },
    showBorder: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      height: chartHeight,
      width: 0,
    };
  },
  computed: {
    chartData() {
      // TODO: use the data from graphData
      let data = [[5, 0, 5], [2, 5, 1], [3, 2, 0], [5, 3, 4], [0, 4, 10], [0, 5, 4], [0, 6, 6]];
      data = data.map(item => [item[1], item[0], item[2] || '-']);

      return data;
    },
    xAxisName() {
      return this.graphData.queries[0].result[0].x_label !== undefined
        ? this.graphData.queries[0].result[0].x_label
        : '';
    },
    yAxisName() {
      return this.graphData.queries[0].result[0].y_label !== undefined
        ? this.graphData.queries[0].result[0].y_label
        : '';
    },
    xAxisLabels() {
      // TODO: use the data from graphData
      return ['12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];
    },
    yAxisLabels() {
      // TODO: use the data from graphData
      return ['Sat', 'Fri', 'Thu', 'Wed', 'Tue', 'Mon', 'Sun'];
    },
  },
  watch: {
    containerWidth: 'onResize',
  },
  beforeDestroy() {
    window.removeEventListener('resize', debouncedResize);
  },
  created() {
    debouncedResize = debounceByAnimationFrame(this.onResize);
    window.addEventListener('resize', debouncedResize);
  },
  methods: {
    onResize() {
      if (!this.$refs.areaChart) return;
      const { width } = this.$refs.areaChart.$el.getBoundingClientRect();
      this.width = width;
    },
  },
};
</script>
<template>
  <div class="prometheus-graph col-12" :class="[showBorder ? 'p-2' : 'p-0']">
    <div :class="{ 'prometheus-graph-embed w-100 p-3': showBorder }">
      <div class="prometheus-graph-header">
        <h5 class="prometheus-graph-title js-graph-title">{{ graphData.title }}</h5>
      </div>
      <gl-heatmap
        ref="heatmapChart"
        v-bind="$attrs"
        :data-series="chartData"
        :x-axis-name="xAxisName"
        :y-axis-name="yAxisName"
        :x-axis-labels="xAxisLabels"
        :y-axis-labels="yAxisLabels"
        :height="height"
        :width="width"
      />
    </div>
  </div>
</template>
