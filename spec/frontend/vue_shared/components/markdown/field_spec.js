import $ from 'jquery';
import Vue from 'vue';
import fieldComponent from '~/vue_shared/components/markdown/field.vue';
import { mount } from '@vue/test-utils';
import '~/behaviors/markdown/render_gfm';

function assertMarkdownTabs(isWrite, writeLink, previewLink, vm) {
  expect(writeLink.parentNode.classList.contains('active')).toEqual(isWrite);
  expect(previewLink.parentNode.classList.contains('active')).toEqual(!isWrite);
  expect(vm.$el.querySelector('.md-preview-holder').style.display).toEqual(isWrite ? 'none' : '');
}

describe('Markdown field component', () => {
  let vm;
  let wrapper;

  beforeEach(() => {
    wrapper = mount(
      {
        components: {
          fieldComponent,
        },
        data() {
          return {
            text: 'testing\n123',
          };
        },
        template: `
        <field-component
          markdown-preview-path="/preview"
          markdown-docs-path="/docs"
        >
          <textarea
            slot="textarea"
            v-model="text">
          </textarea>
        </field-component>
      `,
      },
      {
        mocks: {
          $http: {
            post: () =>
              Promise.resolve({
                json() {
                  return {
                    body: '<p>markdown preview</p>',
                  };
                },
              }),
          },
        },
      },
    );

    ({ vm } = wrapper);

    return Vue.nextTick();
  });

  describe('mounted', () => {
    it('renders textarea inside backdrop', () => {
      expect(vm.$el.querySelector('.zen-backdrop textarea')).not.toBeNull();
    });

    describe('markdown preview', () => {
      let previewLink;
      let writeLink;

      beforeEach(() => {
        previewLink = vm.$el.querySelector('.nav-links .js-preview-link');
        writeLink = vm.$el.querySelector('.nav-links .js-write-link');
      });

      it('sets preview link as active', () => {
        previewLink.click();

        return Vue.nextTick().then(() => {
          expect(previewLink.parentNode.classList.contains('active')).toBeTruthy();
        });
      });

      it('shows preview loading text', () => {
        previewLink.click();

        const holder = vm.$el.querySelector('.md-preview-holder');

        return Vue.nextTick().then(() => {
          expect(holder.textContent.trim()).toContain('Loading…');
        });
      });

      it('renders markdown preview', () => {
        previewLink.click();

        // wait for request to complete
        jest.runAllTicks();

        return Vue.nextTick().then(() => {
          expect(vm.$el.querySelector('.md-preview-holder').innerHTML).toContain(
            '<p>markdown preview</p>',
          );
        });
      });

      it('renders GFM with jQuery', () => {
        jest.spyOn($.fn, 'renderGFM').mockImplementation(() => {});

        previewLink.click();

        // wait for request to complete
        jest.runAllTicks();

        return Vue.nextTick()
          .then(() => Vue.nextTick())
          .then(() => {
            expect($.fn.renderGFM).toHaveBeenCalled();
          });
      });

      it('clicking already active write or preview link does nothing', () => {
        writeLink.click();
        return Vue.nextTick()
          .then(() => assertMarkdownTabs(true, writeLink, previewLink, vm))
          .then(() => writeLink.click())
          .then(() => Vue.nextTick())
          .then(() => assertMarkdownTabs(true, writeLink, previewLink, vm))
          .then(() => previewLink.click())
          .then(() => Vue.nextTick())
          .then(() => assertMarkdownTabs(false, writeLink, previewLink, vm))
          .then(() => previewLink.click())
          .then(() => Vue.nextTick())
          .then(() => assertMarkdownTabs(false, writeLink, previewLink, vm));
      });
    });

    describe('markdown buttons', () => {
      it('converts single words', () => {
        const textarea = vm.$el.querySelector('textarea');

        textarea.setSelectionRange(0, 7);
        vm.$el.querySelector('.js-md').click();

        return Vue.nextTick().then(() => {
          expect(textarea.value).toContain('**testing**');
        });
      });

      it('converts a line', () => {
        const textarea = vm.$el.querySelector('textarea');

        textarea.setSelectionRange(0, 0);
        vm.$el.querySelectorAll('.js-md')[5].click();

        return Vue.nextTick().then(() => {
          expect(textarea.value).toContain('*  testing');
        });
      });

      it('converts multiple lines', () => {
        const textarea = vm.$el.querySelector('textarea');

        textarea.setSelectionRange(0, 50);
        vm.$el.querySelectorAll('.js-md')[5].click();

        return Vue.nextTick().then(() => {
          expect(textarea.value).toContain('* testing\n* 123');
        });
      });
    });
  });
});
