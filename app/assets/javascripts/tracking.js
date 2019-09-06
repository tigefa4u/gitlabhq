import _ from 'underscore';

const DEFAULT_SNOWPLOW_OPTIONS = {
  namespace: 'gl',
  hostname: window.location.hostname,
  cookieDomain: window.location.hostname,
  appId: '',
  userFingerprint: false,
  respectDoNotTrack: true,
  forceSecureTracker: true,
  eventMethod: 'post',
  contexts: { webPage: true },
  // Page tracking tracks a single event when the page loads.
  pageTrackingEnabled: false,
  // Activity tracking tracks when a user is still interacting with the page.
  // Events like scrolling and mouse movements are used to determine if the
  // user has the tab focused and is still actively engaging.
  activityTrackingEnabled: false,
};

export default class Tracking {
  static trackable() {
    return !['1', 'yes'].includes(
      window.doNotTrack || navigator.doNotTrack || navigator.msDoNotTrack,
    );
  }

  static enabled() {
    return typeof window.snowplow === 'function' && this.trackable();
  }

  static event(category = document.body.dataset.page, action = 'generic', data = {}) {
    if (!this.enabled()) return false;
    // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
    if (!category) throw new Error('Tracking: no category provided for tracking.');

    const { label, property, value, context } = data;
    const contexts = context ? [context] : undefined;
    return window.snowplow('trackStructEvent', category, action, label, property, value, contexts);
  }

  static install(Vue, defaults = {}) {
    Vue.mixin({
      methods: {
        track(action, data) {
          let category = defaults.category || data.category;
          // eslint-disable-next-line no-underscore-dangle
          category = category || this.$options.name || this.$options._componentTag;
          Tracking.event(category || 'unspecified', action, { ...defaults, ...data });
        },
      },
    });
  }

  static bindDocument(category = document.body.dataset.page, documentOverride = null) {
    const el = documentOverride || document;
    if (!this.enabled() || el.trackingBound) return [];

    el.trackingBound = true;

    const handlers = this.eventHandlers(category);
    handlers.forEach(event => el.addEventListener(event.name, event.func));
    return handlers;
  }

  static eventHandlers(category) {
    const handler = opts => e => this.handleEvent(e, { ...{ category }, ...opts });
    const handlers = [];
    handlers.push({ name: 'click', func: handler() });
    handlers.push({ name: 'show.bs.dropdown', func: handler({ suffix: '_show' }) });
    handlers.push({ name: 'hide.bs.dropdown', func: handler({ suffix: '_hide' }) });
    return handlers;
  }

  static handleEvent(e, opts = {}) {
    const el = e.target.closest('[data-track-event]');
    const action = el && el.dataset.trackEvent;
    if (!action) return;

    const data = {
      label: el.dataset.trackLabel,
      property: el.dataset.trackProperty,
      value: this.elementValue(el),
      context: el.dataset.trackContext,
    };

    this.event(opts.category, action + (opts.suffix || ''), _.omit(data, _.isUndefined));
  }

  static elementValue(el) {
    let value = el.dataset.trackValue || el.value || undefined;
    if (el.type === 'checkbox' && !el.checked) value = false;
    return value;
  }
}

export function initUserTracking() {
  if (!Tracking.enabled()) return;

  const opts = { ...DEFAULT_SNOWPLOW_OPTIONS, ...window.snowplowOptions };
  window.snowplow('newTracker', opts.namespace, opts.hostname, opts);

  if (opts.activityTrackingEnabled) window.snowplow('enableActivityTracking', 30, 30);
  if (opts.pageTrackingEnabled) window.snowplow('trackPageView'); // must be after enableActivityTracking

  Tracking.bindDocument();
}
