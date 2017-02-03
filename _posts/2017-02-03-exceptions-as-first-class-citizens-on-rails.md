---
layout: post
title:  "Exceptions as first-class citizens on Rails"
date: 2017-02-03
categories: guides
tags: ruby rails exceptions
---

I want to share a pattern that I've repeated multiple times in the past when developing API-s with Rails, which grants the ability to respond to invalid requests with a standardized message format by raising an exception.

To be clear, I'm talking about _exceptions_, and not _errors_. To quote a [Haskell wiki page on the topic](https://wiki.haskell.org/Error_vs._Exception):

> ...we use the term exception for **expected but irregular situations** at runtime and the term error for **mistakes in the running program** that can be resolved only by fixing the program.

A few examples of exceptions would be a client which supplies invalid authentication credentials, or one supplying insufficient data for an operation, etc.

## Preview of the end result

To decide whether this interests you, have a look at the end result - a few exception responses:


```ruby
raise Users::AuthenticationFailure # => HTTP 401
```

```json
{
  "code": "authentication_failure",
  "message": "Could not validate authorization",
  "description": "Please authenticate and acquire JWT before attempting to access restricted routes. JWT should be passed in the Authorization header."
}
```

```ruby
raise Users::ValidationFailure.new(user) # => HTTP 422
```

```json
{
  "code": "validation_failure",
  "message": "Validation of params failed",
  "description": "The server could not validate the parameters present with the request. Please check the validation_errors key (hash) for more details.",
  "validation_errors": {
    "name": [ "cannot be blank" ],
    "email": ["does not look like an email address"]
  }
}
```

Let's dig in!

## First-class

I organize my exceptions inside the `app` folder, treating it as equal to any of the other piece of the Rails application:

```
Rails.root
├── app
... ├── channels
    ├── controllers
    ├── exceptions
    │   ├── users
    │   │   ├── authentication_failed_exception.rb
    │   │   └── validation_failure_exception.rb
    │   └── application_exception.rb
    ├── jobs
    ...
```

## Exception classes

Each exception class sets four instance variables that describe the exception.

```ruby
module Users
  class AuthenticationFailureException < ApplicationException
    def initialize
      @code = :authentication_failure
      @message = 'Could not validate authorization'
      @description = 'Please authenticate and acquire JWT before attempting to access restricted routes. JWT should be passed in the Authorization header.'
      @status = 401
    end
  end
end
```

* `code` is useful for clients to programmatically handle these responses.
* `message` is a short error message.
* `description` is a longer message that can help developers understand the reason for the exception, and fix or incorporate it into the design of the client.
* `status` is an over-ride status code for the HTTP response.

## ApplicationException

The `ApplicationException` class defines the response object and a default HTTP status code.

```ruby
class ApplicationException < StandardError
  def response
    { code: @code, message: @message, description: @description }
  end

  def status
    @status || 422
  end
end
```

## Bringing it to life with rescue_from

On the `ApplicationController`, we handle raised `ApplicationException`-s as follows:

```ruby
class ApplicationController < ActionController::API
  # ...
  rescue_from ApplicationException, with: :show_exception
  # ...

  protected

  def show_exception(exception)
    render json: exception.response, status: exception.status
  end
end
```

This allows us to raise custom exceptions from any location while handling a request.

## Adding more detail to exceptions

Note that the second preview example included a `validation_errors` key with extra information about the event. Using plain objects allows us to add or modify the response as per our requirements.

```ruby
module Users
  class ValidationFailureException < ApplicationException
    def initialize(user)
      @code = :validation_failure
      @message = 'Validation of params failed'
      @description = 'The server could not validate the parameters present with the request. Please check the validation_errors key (hash) for more details.'
      @user = user
    end

    def response
      super.merge({ validation_errors: @user.errors })
    end
  end
end
```

## Conclusion

I've used variants of this pattern multiple times over the years, and find it a _clean_ way to handle _exceptional_ situations that require a simple response to indicate failure. To see this pattern in action in a project, check out [GoDreams Admin Server](https://github.com/godreams/admin-server).
