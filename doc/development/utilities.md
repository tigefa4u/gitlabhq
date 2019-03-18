# GitLab utilities

We developed a number of utilities to ease development.

## [`MergeHash`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/utils/merge_hash.rb)

- Deep merges an array of hashes:

    ``` ruby
    Gitlab::Utils::MergeHash.merge(
      [{ hello: ["world"] },
       { hello: "Everyone" },
       { hello: { greetings: ['Bonjour', 'Hello', 'Hallo', 'Dzien dobry'] } },
        "Goodbye", "Hallo"]
    )
    ```

    Gives:

    ``` ruby
    [
      {
        hello:
          [
            "world",
            "Everyone",
            { greetings: ['Bonjour', 'Hello', 'Hallo', 'Dzien dobry'] }
          ]
      },
      "Goodbye"
    ]
    ```

- Extracts all keys and values from a hash into an array:

    ``` ruby
    Gitlab::Utils::MergeHash.crush(
      { hello: "world", this: { crushes: ["an entire", "hash"] } }
    )
    ```

    Gives:

    ``` ruby
    [:hello, "world", :this, :crushes, "an entire", "hash"]
    ```

## [`Override`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/utils/override.rb)

- This utility could help us check if a particular method would override
  another method or not. It has the same idea of Java's `@Override` annotation
  or Scala's `override` keyword. However we only do this check when
  `ENV['STATIC_VERIFICATION']` is set to avoid production runtime overhead.
  This is useful to check:

    - If we have typos in overriding methods.
    - If we renamed the overridden methods, making original overriding methods
      overrides nothing.

    Here's a simple example:

    ``` ruby
    class Base
      def execute
      end
    end

    class Derived < Base
      extend ::Gitlab::Utils::Override

      override :execute # Override check happens here
      def execute
      end
    end
    ```

    This also works on modules:

    ``` ruby
    module Extension
      extend ::Gitlab::Utils::Override

      override :execute # Modules do not check this immediately
      def execute
      end
    end

    class Derived < Base
      prepend Extension # Override check happens here, not in the module
    end
    ```

## [`StrongMemoize`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/utils/strong_memoize.rb)

- Memoize the value even if it is `nil` or `false`.

    We often do `@value ||= compute`, however this doesn't work well if
    `compute` might eventually give `nil` and we don't want to compute again.
    Instead we could use `defined?` to check if the value is set or not.
    However it's tedious to write such pattern, and `StrongMemoize` would
    help us use such pattern.

    Instead of writing patterns like this:

    ``` ruby
    class Find
      def result
        return @result if defined?(@result)

        @result = search
      end
    end
    ```

    We could write it like:

    ``` ruby
    class Find
      include Gitlab::Utils::StrongMemoize

      def result
        strong_memoize(:result) do
          search
        end
      end
    end
    ```

- Clear memoization

    ``` ruby
    class Find
      include Gitlab::Utils::StrongMemoize
    end

    Find.new.clear_memoization(:result)
    ```

## [`RequestCache`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/cache/request_cache.rb)

This module provides a simple way to cache values in RequestStore,
and the cache key would be based on the class name, method name,
optionally customized instance level values, optionally customized
method level values, and optional method arguments.

A simple example that only uses the instance level customised values:

``` ruby
class UserAccess
  extend Gitlab::Cache::RequestCache

  request_cache_key do
    [user&.id, project&.id]
  end

  request_cache def can_push_to_branch?(ref)
    # ...
  end
end
```

This way, the result of `can_push_to_branch?` would be cached in
`RequestStore.store` based on the cache key. If `RequestStore` is not
currently active, then it would be stored in a hash saved in an
instance variable, so the cache logic would be the same.

We can also set different strategies for different methods:

``` ruby
class Commit
  extend Gitlab::Cache::RequestCache

  def author
    User.find_by_any_email(author_email)
  end
  request_cache(:author) { author_email }
end
```

## Popen

This [`Popen`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/popen.rb)
module provides a safe way to call the Ruby Standard Library method
`Open3.popen3`. It avoids potential deadlocks by ensuring that standard
out and standard error pipes are drained in separate threads before
returning a response.

TIP: **Tip:**
If you do not need to read the standard error output, use the
Ruby Standard Library
[`Open3.popen2`](http://ruby-doc.org/stdlib-2.5.3/libdoc/open3/rdoc/Open3.html#method-c-popen2)
instead.

This module has two methods:

- [`popen`](#popen-method)
- [`popen_with_detail`](#popen_with_detail)

### <span id="popen-method">`popen`</span>

``` ruby
Gitlab::Popen.popen(%w[echo "hello, world!"])
```

This method returns a simple array comprised of `[output, exit_code]`:

- The first element of the array contains a string with all standard out
  and standard error output of the command
- The second element of the array contains the exit code of the command

### `popen_with_detail`

```ruby
Gitlab::Popen.popen_with_detail(%w[echo "hello, world!"])
```

This method returns a `Struct` with the following properties:

- `cmd`: the command that was executed.
- `stdout`: all standard out response of the command.
- `stderr`: all standard error response of the command.
- `status`: a
  [`Process::Status` object](https://ruby-doc.org/core-2.5.3/Process/Status.html)
  containing information about the exit status of the command.
- `duration`: the elapsed time in seconds of the command.

### Extend your class with the module

If your class will call methods in `Gitlab::Popen` more than once then
consider extending the module to mix the methods into your class:

```ruby
class MyService
  extend Gitlab::Popen

  def execute
    popen(%w[echo "hello, world!"])
  end
end
```
