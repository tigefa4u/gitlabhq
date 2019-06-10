import { shallowMount, createLocalVue } from '@vue/test-utils';
import IssueComponent from '~/issues/components/issue.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { singleIssueData } from '../mock_data';

const localVue = createLocalVue();

describe('Issue component', () => {
  let wrapper;

  const factory = (props = {}, options = {}) => {
    const propsData = {
      issue: singleIssueData,
      isBulkUpdating: false,
      canBulkUpdate: true,
      ...props,
    };

    wrapper = shallowMount(localVue.extend(IssueComponent), {
      localVue,
      propsData,
      ...options,
    });
  };

  it('renders the issue title', () => {
    factory();

    const issueTitle = wrapper.find('.issue-title-text > a');

    expect(issueTitle.exists()).toBe(true);
    expect(issueTitle.text()).toBe(singleIssueData.title);
  });

  it('links to the issue details page', () => {
    factory();

    const issueTitle = wrapper.find('.issue-title-text > a');

    expect(issueTitle.attributes('href')).toBe(singleIssueData.web_url);
  });

  it('renders issue confidential icon', () => {
    factory();

    const confidentialIcon = wrapper.find('.js-issue-confidential-icon');

    expect(confidentialIcon.exists()).toBe(true);
  });

  it('renders issue tasks', () => {
    const issue = { ...singleIssueData };
    issue.has_tasks = true;
    issue.task_status = '0 or 2 completed';

    factory({ issue });

    const issueTasksWrapper = wrapper.find('.task-status');

    expect(issueTasksWrapper.exists()).toBe(true);
    expect(issueTasksWrapper.text()).toBe(issue.task_status);
  });

  it('renders issue reference path', () => {
    factory();

    const referencePath = wrapper.find('.issuable-reference');

    expect(referencePath.exists()).toBe(true);
    expect(referencePath.text()).toBe(singleIssueData.reference_path);
  });

  it('renders issue created date', () => {
    factory();

    const issueCreatedDate = wrapper.find('.issuable-authored').find(TimeAgoTooltip);

    expect(issueCreatedDate.exists()).toBe(true);
    expect(issueCreatedDate.props('time')).toBe(singleIssueData.created_at);
  });

  it('renders issue author', () => {
    factory();

    const issueAuthor = wrapper.find('.issuable-authored .author-link');

    expect(issueAuthor.exists()).toBe(true);
    expect(issueAuthor.text()).toBe(singleIssueData.author.name);
    expect(issueAuthor.attributes('href')).toBe(singleIssueData.author.web_url);
  });

  it('renders issue milestone', () => {
    const issue = { ...singleIssueData };
    issue.milestone = {
      web_url: 'http://hello.world',
      title: 'Hello milestone',
    };

    factory({ issue });

    const issueMilestone = wrapper.find('.issuable-milestone');

    expect(issueMilestone.exists()).toBe(true);
    expect(issueMilestone.text()).toBe(issue.milestone.title);
    expect(issueMilestone.find('a').attributes('href')).toBe(issue.milestone.web_url);
  });

  it('renders issue weight', () => {
    factory();

    const issueWeight = wrapper.find('.issuable-weight');

    expect(issueWeight.exists()).toBe(true);
    expect(issueWeight.text()).toBe(`${singleIssueData.weight}`);
  });

  it('renders issue "CLOSED" if issue is closed', () => {
    const issue = { ...singleIssueData };
    issue.state = 'closed';

    factory({ issue });

    const issueStateWrapper = wrapper.find('.issuable-status');

    expect(issueStateWrapper.exists()).toBe(true);
    expect(issueStateWrapper.text()).toBe('CLOSED');
  });

  it('renders issue merge request count', () => {
    const issue = { ...singleIssueData };
    issue.merge_requests_count = '20';

    factory({ issue });

    const issueMRCount = wrapper.find('.issuable-mr');

    expect(issueMRCount.exists()).toBe(true);
    expect(issueMRCount.text()).toBe(issue.merge_requests_count);
  });

  describe('Issue upvotes', () => {
    let issue;

    beforeEach(() => {
      issue = { ...singleIssueData };
      issue.upvotes = '5';
    });

    it('does not render if upvotes is 0', () => {
      issue.upvotes = 0;

      factory({ issue });

      const issueUpvotes = wrapper.find('.issuable-upvotes');

      expect(issueUpvotes.exists()).toBe(false);
    });

    it('renders upvotes count', () => {
      factory({ issue });

      const issueUpvotes = wrapper.find('.issuable-upvotes');

      expect(issueUpvotes.exists()).toBe(true);
      expect(issueUpvotes.text()).toBe(issue.upvotes);
    });
  });

  describe('Issue downvotes', () => {
    let issue;

    beforeEach(() => {
      issue = { ...singleIssueData };
      issue.downvotes = '5';
    });

    it('does not render if downvotes is 0', () => {
      issue.downvotes = 0;

      factory({ issue });

      const issueDownvotes = wrapper.find('.issuable-downvotes');

      expect(issueDownvotes.exists()).toBe(false);
    });

    it('renders downvotes count', () => {
      factory({ issue });

      const issueDownvotes = wrapper.find('.issuable-downvotes');

      expect(issueDownvotes.exists()).toBe(true);
      expect(issueDownvotes.text()).toBe(issue.downvotes);
    });
  });

  describe('Issue comments', () => {
    let issue;

    beforeEach(() => {
      issue = { ...singleIssueData };
      issue.note_count = '5';
    });

    it('renders 0 if the issue has no comments', () => {
      issue.note_count = null;

      factory({ issue });

      const issueComments = wrapper.find('.issuable-comments');

      expect(issueComments.text()).toBe('0');
    });

    it('renders issue comments count', () => {
      factory({ issue });

      const issueComments = wrapper.find('.issuable-comments');
      expect(issueComments.text()).toBe(issue.note_count);
    });
  });
});
