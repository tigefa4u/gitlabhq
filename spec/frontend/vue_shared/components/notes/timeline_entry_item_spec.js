import { createWrapperFactory } from 'helpers/component_wrapper';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

describe('TimelineEntryItem', () => {
  const createWrapper = createWrapperFactory(TimelineEntryItem);

  const findContent = () => wrapper.find('.timeline-entry-inner :first-child');

  it('renders correctly', () => {
    createWrapper();

    expect(wrapper.is('.timeline-entry')).toBe(true);
    expect(wrapper.contains('.timeline-entry-inner')).toBe(true);
  });

  it('accepts default slot', () => {
    const dummyContent = '<p>some content</p>';

    createWrapper({
      slots: {
        default: dummyContent,
      },
    });

    expect(findContent().html()).toBe(dummyContent);
  });
});
