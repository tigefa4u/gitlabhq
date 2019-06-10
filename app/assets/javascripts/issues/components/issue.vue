<script>
import dateFormat from 'dateformat';
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { getDayDifference } from '~/lib/utils/datetime_utility';
import { ISSUE_STATES, MAX_ASSIGNEES_RENDER } from '../constants';
import { sprintf, __ } from '~/locale';

export default {
  components: {
    Icon,
    UserAvatarLink,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
    isBulkUpdating: {
      type: Boolean,
      required: true,
    },
    canBulkUpdate: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    issueClassesList() {
      const classList = ['issue'];
      const issueCreatedToday = !getDayDifference(new Date(this.issue.created_at), new Date());

      if (this.issueIsClosed) {
        classList.push('closed');
      }

      if (issueCreatedToday) {
        classList.push('today');
      }

      return classList;
    },
    formatDueDate() {
      return dateFormat(this.issue.due_date, 'mmm d, yyyy');
    },
    isIssueOverDue() {
      return getDayDifference(new Date(), new Date(this.issue.due_date)) < 0;
    },
    shouldAssigneeRenderCounter() {
      return this.issue.assignees.length - MAX_ASSIGNEES_RENDER > 0;
    },
    moreAssigneesCount() {
      return this.issue.assignees.length - MAX_ASSIGNEES_RENDER;
    },
    assigneeCounterTooltip() {
      return sprintf('+%{moreAssigneesCount} more assignees', {
        moreAssigneesCount: this.moreAssigneesCount,
      });
    },
    issueCommentsURL() {
      return `${this.issue.web_url}#notes`;
    },
    bulkUpdateId() {
      return `selected_issue_${this.issue.id}`;
    },
    issueIsClosed() {
      return this.issue.state === ISSUE_STATES.CLOSED;
    },
    assigneesToRender() {
      return this.issue.assignees.filter((assignee, index) => index < MAX_ASSIGNEES_RENDER);
    },
    hasRelatedMergeRequests() {
      return this.issue.merge_requests_count > 0;
    },
    hasUpvotes() {
      return this.issue.upvotes > 0;
    },
    hasDownvotes() {
      return this.issue.downvotes > 0;
    },
    hasComments() {
      return this.issue.note_count < 0;
    },
  },
  methods: {
    getAvatarTitle(assignee) {
      return sprintf('Assigned to %{name}', { name: assignee.name });
    },
    labelStyle(label) {
      return {
        backgroundColor: label.color,
        color: label.text_color,
      };
    },
  },
  confidentialText: __('Confidential'),
};
</script>
<template>
  <li :id="`issue_${issue.id}`" :url="issue.web_url" :class="issueClassesList" data-labels="[]">
    <div class="issue-box">
      <div v-if="canBulkUpdate" class="issue-check" :class="{ hidden: !isBulkUpdating }">
        <input
          :id="bulkUpdateId"
          type="checkbox"
          class="selected-issuable"
          :name="bulkUpdateId"
          :data-id="issue.id"
        />
      </div>
      <div class="issuable-info-container">
        <div class="issuable-main-info">
          <div class="issue-title title">
            <span class="issue-title-text">
              <span
                v-if="issue.confidential"
                v-gl-tooltip
                :title="$options.confidentialText"
                :aria-label="$options.confidentialText"
              >
                <icon name="eye-slash" class="align-text-bottom js-issue-confidential-icon" />
              </span>
              <a :href="issue.web_url">{{ issue.title }}</a>
              <span v-if="issue.has_tasks" class="task-status d-none d-sm-inline-block">
                &nbsp;
                {{ issue.task_status }}
              </span>
            </span>
          </div>
          <div class="issuable-info">
            <span class="issuable-reference">{{ issue.reference_path }}</span>
            <span class="issuable-authored d-none d-sm-inline-block">
              &middot; {{ __('opened') }}
              <time-ago-tooltip :time="issue.created_at" tooltip-placement="bottom" />
              by
              <a
                class="author-link js-user-link"
                :data-user-id="issue.author.id"
                :data-username="issue.author.username"
                :data-name="issue.author.name"
                :href="issue.author.web_url"
              >
                <span class="author">{{ issue.author.name }}</span>
              </a>
            </span>
            <span v-if="issue.milestone" class="issuable-milestone d-none d-sm-inline-block">
              &nbsp;
              <a :href="issue.milestone.web_url">
                <icon name="clock" class="align-text-bottom" />
                {{ issue.milestone.title }}
              </a>
            </span>
            <span
              v-if="issue.due_date"
              v-gl-tooltip
              class="issuable-due-date d-none d-sm-inline-block"
              :title="__('Due date')"
              :class="{ cred: isIssueOverDue }"
            >
              &nbsp;
              <icon name="calendar" class="align-text-bottom" />
              {{ formatDueDate }}
            </span>
            <span v-if="issue.labels">
              <span
                v-for="label in issue.labels"
                :key="label.id"
                ref="button"
                class="label-link append-right-4 cursor-pointer"
                @click="$emit('issueLabelClicked', label.name)"
              >
                <span
                  v-gl-tooltip
                  class="badge color-label"
                  :style="labelStyle(label)"
                  :title="label.description"
                >
                  {{ label.name }}
                </span>
              </span>
            </span>
            <span
              v-if="issue.weight"
              v-gl-tooltip
              :title="__('Weight')"
              class="issuable-weight d-none d-sm-inline-block"
            >
              <icon name="weight" class="align-text-bottom issue-weight-icon" />
              {{ issue.weight }}
            </span>
          </div>
        </div>
        <div class="issuable-meta">
          <ul class="controls">
            <li v-if="issueIsClosed" class="issuable-status">{{ __('CLOSED') }}</li>
            <li v-if="issue.assignees.length">
              <user-avatar-link
                v-for="assignee in assigneesToRender"
                :key="assignee.id"
                :link-href="assignee.web_url"
                :img-alt="getAvatarTitle(assignee)"
                :img-src="assignee.avatar_url"
                :img-size="16"
                :tooltip-text="getAvatarTitle(assignee)"
                tooltip-placement="bottom"
              />
              <span
                v-if="shouldAssigneeRenderCounter"
                v-gl-tooltip
                :title="assigneeCounterTooltip"
                class="avatar-counter"
                data-placement="bottom"
              >
                +{{ moreAssigneesCount }}
              </span>
            </li>
            <li
              v-if="hasRelatedMergeRequests"
              v-gl-tooltip
              class="issuable-mr d-none d-sm-block"
              :title="__('Related merge requests')"
            >
              <icon name="merge-request" class="align-text-bottom icon-merge-request-unmerged" />
              {{ issue.merge_requests_count }}
            </li>

            <li
              v-if="hasUpvotes"
              v-gl-tooltip
              class="issuable-upvotes d-none d-sm-block"
              :title="__('Upvotes')"
            >
              <icon name="thumb-up" class="align-text-bottom" />
              {{ issue.upvotes }}
            </li>

            <li
              v-if="hasDownvotes"
              v-gl-tooltip
              class="issuable-downvotes d-none d-sm-block"
              :title="__('Downvotes')"
            >
              <icon name="thumb-down" class="align-text-bottom" />
              {{ issue.downvotes }}
            </li>

            <li class="issuable-comments d-none d-sm-block">
              <a
                v-gl-tooltip
                :href="issueCommentsURL"
                :class="{ 'no-comments': hasComments }"
                :title="__('Comments')"
              >
                <icon name="comments" class="align-text-bottom" />
                {{ issue.note_count || 0 }}
              </a>
            </li>
          </ul>
          <div class="float-right issuable-updated-at d-none d-sm-inline-block">
            <span>
              updated
              <time-ago-tooltip
                :time="issue.updated_at"
                tooltip-placement="bottom"
                css-class="issue_update_ago"
              />
            </span>
          </div>
        </div>
      </div>
    </div>
  </li>
</template>
