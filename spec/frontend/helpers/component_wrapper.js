/* eslint-disable import/prefer-default-export, global-require, import/no-dynamic-require */
import { shallowMount, createLocalVue } from '@vue/test-utils';

const localVue = createLocalVue();

export const destroyWrapper = () => {
  if (global.wrapper) {
    global.wrapper.destroy();
    global.wrapper = null;
  }
};

export const createWrapperFactory = (component, destroyHook = afterEach) => {
  const createWrapper = options => {
    if (global.wrapper) {
      throw new Error('You need to call destroyWrapper() before creating a new wrapper instance!');
    }

    global.wrapper = shallowMount(component, {
      localVue,

      // async will become default in the next release
      // https://github.com/vuejs/vue-test-utils/issues/1137
      sync: false,

      ...options,
    });

    return global.wrapper;
  };

  destroyHook(destroyWrapper);

  return createWrapper;
};
