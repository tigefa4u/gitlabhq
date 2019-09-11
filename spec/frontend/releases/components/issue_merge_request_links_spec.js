import { shallowMount } from '@vue/test-utils';
import IssueMergeRequestLinks from '~/releases/components/issue_merge_request_links.vue';
import _ from 'underscore';
import { milestones } from '../mock_data';

describe('IssueMergeRequestLinks', () => {
  let wrapper;
  let milestone;
  const issuesUrl = 'http://example.gitlab.com/issues?scope=all';
  const mergeRequestsUrl = 'http://example.gitlab.com/merge_requests?scope=all';

  const factory = milestoneProp => {
    wrapper = shallowMount(IssueMergeRequestLinks, {
      propsData: {
        milestone: milestoneProp,
        issuesUrl,
        mergeRequestsUrl,
      },
      sync: false,
    });
  };

  beforeEach(() => {
    milestone = _.first(milestones);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with the default props', () => {
    beforeEach(() => {
      factory(milestone);
    });

    it('renders the correct issues URL', () => {
      expect(wrapper.find('a[href*=issues]').attributes().href).toBe(
        'http://example.gitlab.com/issues?scope=all&milestone_title=13.6',
      );
    });

    it('renders the correct merge requests URL', () => {
      expect(wrapper.find('a[href*=merge_requests]').attributes().href).toBe(
        'http://example.gitlab.com/merge_requests?scope=all&milestone_title=13.6',
      );
    });

    it('renders the issues link with the appropriate attributes', () => {
      expect(wrapper.find('a[href*=issues]').attributes().target).toBe('_blank');
      expect(wrapper.find('a[href*=issues]').attributes().rel).toBe('noopener noreferrer');
    });

    it('renders the merge requests link with the appropriate attributes', () => {
      expect(wrapper.find('a[href*=merge_requests]').attributes().target).toBe('_blank');
      expect(wrapper.find('a[href*=merge_requests]').attributes().rel).toBe('noopener noreferrer');
    });
  });

  describe('when the milestone title contains URL-unfriendly characters', () => {
    beforeEach(() => {
      milestone.title = 'a/weird/title';
      factory(milestone);
    });

    it('renders the correct issues URL', () => {
      expect(wrapper.find('a[href*=issues]').attributes().href).toBe(
        'http://example.gitlab.com/issues?scope=all&milestone_title=a%2Fweird%2Ftitle',
      );
    });

    it('renders the correct merge requests URL', () => {
      expect(wrapper.find('a[href*=merge_requests]').attributes().href).toBe(
        'http://example.gitlab.com/merge_requests?scope=all&milestone_title=a%2Fweird%2Ftitle',
      );
    });
  });

  describe('when the milestone title contains malicious text', () => {
    beforeEach(() => {
      milestone.title = '<script></script>';
      factory(milestone);
    });

    it('renders the correct issues URL', () => {
      expect(wrapper.find('a[href*=issues]').attributes().href).toBe(
        'http://example.gitlab.com/issues?scope=all&milestone_title=%26lt%3Bscript%26gt%3B%26lt%3B%2Fscript%26gt%3B',
      );
    });

    it('renders the correct merge requests URL', () => {
      expect(wrapper.find('a[href*=merge_requests]').attributes().href).toBe(
        'http://example.gitlab.com/merge_requests?scope=all&milestone_title=%26lt%3Bscript%26gt%3B%26lt%3B%2Fscript%26gt%3B',
      );
    });
  });
});
