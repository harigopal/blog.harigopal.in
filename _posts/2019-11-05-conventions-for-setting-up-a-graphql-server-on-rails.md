---
layout: post
title: "Conventions for setting up a GraphQL Server on Rails"
date: 2019-11-05 20:20:00 +0530
categories: guides
tags: react reasonreact
---

## Introduction

_"Convention over configuration"_ is one of the reasons Rails became as popular as it did. Conventions allow developers to be productive without [_bike-shedding_](https://en.wiktionary.org/wiki/bikeshedding). However, introducing new concepts to Rails involves a period of experimentation during which there are no answers to troublesome questions.

Setting up a GraphQL server on Rails is one of those tasks.

This post presents a method for setting up a GraphQL server, while also tackling two issues that are generally glossed over by existing documentation surrounding the use of the `graphql-ruby` gem:

1. How do I handle authorization?
2. How do I avoid N+1 queries?

### Start with `graphql-ruby`

Use [the gem's documentation](https://graphql-ruby.org/getting_started) to install and get started with `graphql-ruby`. The steps are straight-forward and well-documented, but I suggest not setting up queries and mutations yet - we'll get to that.

Just like with Facebook's documentation about authorization in GraphQL, the [gem's documentation also suggests pushing the responsibility into _business_ logic](https://graphql-ruby.org/authorization/overview.html#authorization-in-your-business-logic), specifically into model methods that accept `context` and decide what kind of relation or data is accessible for _that_ user.

I'd like to suggest an alternative.

### _Resolvers_ authorize and fetch data

Let's start by adding an `ApplicationQuery` class that'll act as the base class for _resolvers_ and _mutators_:

<script src="https://gist.github.com/harigopal/2270db1662f697fbbf8fd3303aca2029.js"></script>

With that in place, we can start writing _resolver_ objects that will help us retrieve properly authorized data for GraphQL queries. Let's take the example of a query that asks for a list of users:

<script src="https://gist.github.com/harigopal/124000d16b0188d283c6ed92763b1f4e.js"></script>

Notice how the `users` method simply hands over the responsibility for loading the data to a `UsersResolver` object:

<script src="https://gist.github.com/harigopal/d498086083b1db7180e407b43dbf7193.js"></script>

What you're looking at is the essence of this approach.

1. All requests are individually authorized.
2. There is an assumption that once a query is authorized, all data returned by the resolver (or mutator) can be accessed by the authenticated user.
3. Avoid N+1-s by making sure that the resolver method `includes` all necessary data for the response.

Before we move onto mutators, let's also look at how we deal with queries that have arguments, using a variation of what we've done above:

<script src="https://gist.github.com/harigopal/d189b80d9d62acdde4bb6e4f8bd4d364.js"></script>

Only a few things are different here:

1. `args` is passed to the resolver in addition to context.
2. There's a `property :id` in the resolver class defining what data the query will work with.
3. Instead of a relation, the `user` method in the resolver returns a `User` object, since the _type_ for the query is a single object.

### _Mutators_ authorize, modify, and supply a response

GraphQL mutations aren't really all that different from queries. Mutations are queries that are, _by convention_, allowed to modify data. And just like queries, they too can return structured data.

As with queries, let's start with a simple example that shows just how similar _mutators_ are to _resolvers_.

<script src="https://gist.github.com/harigopal/da0fe5301af5027e84ec0f0f9a5c83dc.js"></script>

Notice how there's a call to `.valid?` before the `.create_comment` is called. This triggers validations that can be configured in the mutator class:

<script src="https://gist.github.com/harigopal/d64f6273011582b657af7a8a0bc30797.js"></script>

Again, there's very little that's new here.

1. Because `ApplicationQuery` includes `ActiveModel::Model`, we have access to all of the validation methods that we're familiar with.
2. The `property` helper simply combines `validates` and `attr_accessor` into a single-step, and helps avoid bugs because the former depends on the latter.
2. We can either process the request in the mutator directly in the `create_comment` method, or pass it onto a service as shown in the example.

As with queries, there is an assumption that the `create_comment` method will return an object that responds to the _fields_ mentioned in the mutation class. In this case, that's `id`, and as long as the service returns a `Comment` object, everything should work as expected.

#### Create types for complex returns

While GraphQL unsubtly suggests the use of relations in your response types, there is no need to follow that pattern. Often, it's much more straight-forward to create a custom type that fits exactly the data that you want to return:

<script src="https://gist.github.com/harigopal/caba32c4f40f70c6ff8204def6281602.js"></script>

Here, the custom `UpdatePostType` is used to compose exactly what the UI requires in this imaginary app, when a post is updated.

### What are the advantages of this approach?

1. You have a self-documenting API. Testing it is a breeze thanks to GraphiQL.
2. Your API is integrated with the editor - it'll suggest names, arguments, and return values - writing correct queries is much simpler.
3. Your compiler will prevent the application from generating code with invalid queries.
4. The Rails server will crash with a useful error message if your code ever disobeys the type specification.
5. Pagination of resources is simple and straight-forward, thanks to [built-in, well-thought-out conventions](https://graphql-ruby.org/relay/connections.html) that cover a large variety of pagination-use-cases.
6. Avoids a lot of bike-shedding. `PUT` vs `PATCH`? `400` vs `422`? How to handle deprecation? These questions, and more, are no longer concerns.
7. The server's response can be extended to include more standardized behavior.

#### About extensibility

Your server always supplies a JSON response. This means that you can add more fields to it if you'd like.

In [PupilFirst](https://www.pupilfirst.com), we've expanded the response object to include a `notifications` field. If present, the response handler in the client automatically converts them into _flash_ notifications that are shown to the user. This helps us preserve a _Rails-like_ experience in our mutators, and keeps notifications _DRY_:

<script src="https://gist.github.com/harigopal/0b208181f942adb7cc5beccbfdd5531a.js"></script>

The query superclass has simple methods that inject notifications into the context...

<script src="https://gist.github.com/harigopal/0b480036b4a5213077c538f49f19f87b.js"></script>

...which then gets placed in the response by the GraphQL controller:

<script src="https://gist.github.com/harigopal/675ef7e93ac142cef4a9d7bc1038b091.js"></script>

### However, concerns still exist

#### This isn't what GraphQL promised

One of the stated advantages of GraphQL is that it solves the problem of over-fetching by allowing the client to specify exactly what data it needs, leading to the server fetching _only_ the asked-for data.

This approach definitely **ignores** that goal. We're taking this approach because of two reasons:

1. Over-fetching is not a problem for [us](https://www.pupilfirst.com). It might become a problem _at scale_, but we're not at that size yet. It's generally better to tackle problems that exist now (ease of API usage, and avoiding clerical mistakes), instead of one that _might_ happen in the future.
2. GraphQL doesn't actually _do_ anything to solve over-fetching - it just specifies how to deliver the data once you've retrieved it. However, retrieving data correctly is [still up to your _business logic_](https://graphql.org/learn/thinking-in-graphs/#business-logic-layer), which is always vaguely defined in all documentation that I've come across.

Arbitrarily loading relational data and incurring huge performance hits is one of the easiest mistakes to make with GraphQL, and it's not a problem whose solution is clear. At this point, I think it's appropriate to mention that Shopify has released a [`graphql-batch` gem](#) that _claims_ to tackle this issue. Unfortunately, I think it's poorly documented, and I couldn't really make sense of how it's supposed to work, but it may be worth looking at if you're already _at scale_, and dealing with issues like over-fetching.

#### Why not authorize fields?

The simple answer is that it's much easier to think about authorizing requests rather than fields. Requests always have a context which can be used to determine whether _this_ user is allowed to access some data or make a change.

However, if the fields that a client can request are unbounded, i.e., the type allows the client to dig deeper into relationships and ask for _distant_ data, then field-level authorization is your only option. This is why we suggest creating response types specific to queries if the requested data is complicated. Yes, this is restrictive, but requires only one authorization, and ensures that we're limiting the response to a selection of data that we know the client is _definitely_ allowed to access.

#### How is this any different from REST?

First, I'd like to point you to the list of advantages written above.

You'll notice that the process I've suggested is very similar to how REST works. And you know what? REST has some _really_ good ideas about how to manage communication - it's just that _some_ of its requirements don't make sense anymore when building APIs. REST has an uncomplicated approach to authorization and data-delivery that I think we should adopt even when we're using GraphQL.

### A real-world example

If you'd like to take a look at a Rails application that uses this approach, take a look at codebase for [the PupilFirst LMS](https://github.com/SVdotCO/pupilfirst). The patterns described here were created as [our team](https://www.sv.co) gradually switched to using ReasonML and ReasonReact on the front-end, and adopted GraphQL in order to leverage the presence of types and a compiler.
