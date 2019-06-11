import { ApolloClient } from 'apollo-client';
import { InMemoryCache, IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import { createUploadLink } from 'apollo-upload-client';
import { ApolloLink } from 'apollo-link';
import { BatchHttpLink } from 'apollo-link-batch-http';
import csrf from '~/lib/utils/csrf';

export default (resolvers = {}, config = {}) => {
  let uri = `${gon.relative_url_root}/api/graphql`;
  const { introspectionQueryResultData, cacheConfig } = config;

  if (config.baseUrl) {
    // Prepend baseUrl and ensure that `///` are replaced with `/`
    uri = `${config.baseUrl}${uri}`.replace(/\/{3,}/g, '/');
  }

  if (introspectionQueryResultData) {
    // eslint-disable-next-line no-param-reassign
    config.cacheConfig = cacheConfig || {};

    // Extract typenames from provided introspection Query data.
    // eslint-disable-next-line no-underscore-dangle
    const typeNames = introspectionQueryResultData.__schema.types
      .map(type => type.possibleTypes)
      .reduce((acc, item) => acc.concat(item), [])
      .map(item => item.name);

    Object.assign(config.cacheConfig, {
      fragmentMatcher: new IntrospectionFragmentMatcher({
        introspectionQueryResultData,
      }),
      dataIdFromObject: obj => {
        // We need to create a dynamic ID for each entry and
        // each entry can have the same ID as the ID in a commit ID,
        // So we create a unique cache ID with the path and the ID.
        // eslint-disable-next-line no-underscore-dangle
        if (typeNames.indexOf(obj.__typename) > -1) {
          return `${obj.flatPath}-${obj.id}`;
        }

        // If the type doesn't match any of the above we
        // fallback to using the default Apollo ID.
        // eslint-disable-next-line no-underscore-dangle
        return obj.id || obj._id;
      },

      // Override addTypename to force it to be
      // `true` to ensure that fragmentMatcher
      // always has `__typename` available.
      addTypename: true,
    });
  }

  const httpOptions = {
    uri,
    headers: {
      [csrf.headerKey]: csrf.token,
    },
  };

  return new ApolloClient({
    link: ApolloLink.split(
      operation => operation.getContext().hasUpload,
      createUploadLink(httpOptions),
      new BatchHttpLink(httpOptions),
    ),
    cache: new InMemoryCache(config.cacheConfig),
    resolvers,
  });
};
