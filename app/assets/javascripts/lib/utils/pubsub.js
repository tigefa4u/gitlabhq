/**
 * @module message_queue
 *
 * Implements a simple, async messaging system with pub/sub mechanics. Useful for getting jQuery controls and Vue components to talk to each other.
 */

const topics = {};

/**
 * Publish a message to a topic with an optional payload. Listeners are invoked asynchronously. If there are no listeners for a topic, nothing happens.
 */
export function publish(topic, payload) {
  const handlers = topics[topic];
  if (!handlers) return;

  handlers.forEach(handler => {
    Promise.resolve()
      .then(() => handler(payload))
      .catch(e => {
        throw e;
      });
  });
}

/**
 * Subscribes to a topic. When a message is published on that topic, the handler will by called.
 * @returns {Function} A function that unsubscribes the handler from the topic.
 */
export function subscribe(topic, handler) {
  topics[topic] = topics[topic] || [];
  topics[topic].push(handler);

  return () => {
    topics[topic] = topics[topic].filter(h => h !== handler);
  };
}
