<script>
import { GlBreadcrumb } from '@gitlab/ui';
import Icon from '../../vue_shared/components/icon.vue';

export default {
  name: 'Breadcrumbs',
  components: {
    Icon,
    GlBreadcrumb,
  },
  inheritsAttrs: false,
  props: {
    items: {
      type: Array,
      required: true,
      default: () => [{ text: '', href: '' }],
    },
    imageSrc: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <gl-breadcrumb :items="items" class="breadcrumbs">
    <img slot="avatar" alt="avatar" class="breadcrumbs-avatar-tile" :src="imageSrc" />
    <icon slot="caret" name="angle-right" :size="8" />
  </gl-breadcrumb>
</template>
