---
layout: post
title: "Conventions for setting up a GraphQL Server on Rails"
categories: guides
tags: react reasonreact
---

## Introduction

_"Convention over configuration"_ is one of the reasons Rails became as popular as it did. Conventions allow developers to be productive without [_bike-shedding_](https://en.wiktionary.org/wiki/bikeshedding). However, introducing new concepts to Rails involves a period of experimentation during which there are no answers to troublesome questions.

Setting up a GraphQL server on Rails is one of those tasks.

This post presents a method for setting up a GraphQL server, while also tackling two issues that are generally glossed over by existing documentation surrounding the use of the `graphql-ruby` gem:

1. How do I handle authorization?
2. How do I avoid N+1 queries?

### Start with `graphql-ruby`.

Use [the gem's documentation](https://graphql-ruby.org/getting_started) to install and get started with `graphql-ruby`. The steps are straight-forward and well-documented, but I suggest not setting up queries and mutations yet - we'll get to that.

Just like with Facebook's documentation about authorization in GraphQL, the [gem's documentation also suggests pushing the responsibility into _business_ logic](https://graphql-ruby.org/authorization/overview.html#authorization-in-your-business-logic), specifically into model methods that accept `context` and decide what kind of relation or data is accessible for _that_ user.

I'd like to suggest an alternative.

### _Resolvers_ authorize and fetch data.

> TODO: Put the `ApplicationQuery` class here, and explain how to use it within _resolver_ classes to retrieve data.

### _Mutators_ authorize, modify, and supply a response.

> TODO: A reminder that mutations are just a _convention_, even within GraphQL. They are queries that are _by convention_ allowed to modify data, and just like queries can return structured data.

### What are the advantages of this approach?

1. You have a self-documenting API. Testing it is a breeze thanks to GraphiQL.
2. Your API is integrated with the editor - it'll suggest names, arguments, and return values - writing correct queries is much simpler.
3. Your compiler will prevent the application from generating code with invalid queries.
4. The Rails server will crash with a useful error message if your code ever disobeys the type specification.
5. Pagination of resources is simple and straight-forward, thanks to built-in, well-thought-out conventions.
6. Avoids a lot of bike-shedding. `PUT` vs `PATCH`? `400` vs `422`? How to handle deprecation? These questions and more are no longer concerns.
7. The server's response can be extended to include more standardized behavior.

#### About extensibility

Your server always supplies a JSON response. This means that you can add more fields to it if you'd like.

In [PupilFirst](https://www.pupilfirst.com), we've expanded the response object to include a `notifications` field. If present, the response handler in the client automatically converts them into _flash_ notifications that are shown to the user. This helps us preserve a _Rails-like_ experience in our mutators, and keeps notifications _DRY_:

<script src="https://gist.github.com/harigopal/0b208181f942adb7cc5beccbfdd5531a.js"></script>

The mutator has simple methods that inject the notifications into the context...

<script src="https://gist.github.com/harigopal/0b480036b4a5213077c538f49f19f87b.js"></script>

...which gets placed in the response by in GraphQL controller:

<script src="https://gist.github.com/harigopal/675ef7e93ac142cef4a9d7bc1038b091.js"></script>

### However, concerns still exist.

#### This isn't what GraphQL promised.

One of the stated advantages of GraphQL is that it solves the problem of over-fetching by allowing the client to specify exactly what data it needs, leading to the server fetching _only_ the asked-for data.

This approach definitely **ignores** that goal. We're taking this approach because of two reasons:

1. Over-fetching is not a problem for us. It might become a problem _at scale_, but we're not at that size yet. It's generally better to tackle problems that exist now (ease of API usage, and avoiding clerical mistakes), instead of one that _might_ happen in the future.
2. GraphQL doesn't actually _do_ anything to solve over-fetching - it just specifies how to deliver the data once you're retrieved it. However, retrieving data correctly is [still up to your _business logic_](https://graphql.org/learn/thinking-in-graphs/#business-logic-layer), which is always vaguely defined in all documentation that I've come across.

At this point, I think it's appropriate to mention that Shopify has released a [`graphql-batch` gem](#) that _claims_ to tackle the issue of over-fetching. Unfortunately, I think it's poorly documented, and I couldn't really make sense of how it's supposed to work, but it may be worth looking at if you're already _at scale_, and dealing with issues like over-fetching.

#### Why not authorize fields?

The simple answer is that it's much easier to think about authorizing requests rather than fields. Requests always have a context which can be used to determine whether _this_ user is allowed to access some data or make a change.

However, if the fields that a client can request are unbounded, i.e., the type allows the client to dig deeper into relationships and ask for _distant_ data, then field-level authorization is your only option. This is why we suggest creating response types specific to queries if the requested data is complicated. Yes, this is restrictive, but requires only one authorization, and ensures that we're limiting the response to a selection of data that we know the client is _definitely_ allowed to access.

You'll notice that this is pretty much how REST works. And you know what? REST is _really_ good at this. It's an uncomplicated approach to authorization and data-delivery that I think it is still perfectly fine for the vast majority of web-apps.

## Random notes - can be included or cleaned up before posting.

### What about optional fields?

GraphQL is _typed_, and the main advantage types give us is that it informs us with an error if the program encounters a type that doesn't fit the _specification_. However, if our query types need to be _flexible_, and allow some fields to be present for some users (via authorization), and not for others, the type will have to be _nullable_.

### Where is all of this heading?

While my feelings on this topic are a bit muddled, I agree with this piece written by my friend Jasim, about how there is [a gap in the programming world for a next-generation web development framework](https://protoship.io/blog/rails-on-ocaml/) written in a typed functional programming language.

However, that day is not yet here, and an (adapted) Rails app still allows us to be productive while still having access to the many years of awesome work that has gone into making Rails the most _ergonomically friendly_ framework, or have anything akin to its incredibly huge and helpful community that has spawned a veritable _ecosystem_ of libraries.

### Working with PupilFirst

While working on [PupilFirst](https://www.pupilfirst), our team at SV.CO found ourselves steadily moving away from a traditional server-rendered UI to _richer_ components which were much easier to _reason_ about and implement with _React_. Very soon, we switched to using [ReasonML](https://reasonml.github.io) as our front-end language of choice to gain access to its incredible type system and first-class support for functional programming concepts.

While [ReasonReact](https://reasonml.github.io/reason-react/) components are _visually_ very similar to React components written with JS, the one striking difference is that ReasonML is _strongly typed_. Communication between components and our Rails endpoints was always a bit awkward, with every API call needing an _encode_ and _decode_ process.

Enter [GraphQL](https://graphql.org/) and the awesome [`graphql-ruby`](https://github.com/rmosolgo/graphql-ruby) gem for Rails.

GraphQL is the most viable replacement for _REST_ that I'm aware of. It is _typed_ (more about this later) and has _conventions_ that make it perfect for building API-s. Most importantly, because it was built from the ground-up as a communication protocol for API-s, it sheds a _lot_ of concepts from _REST_ that actively promote bike-shedding.

Working on [PupilFirst](https://www.pupilfirst.com) has allowed our team at SV.CO to develop a few patterns to effectively set up new GraphQL mutations and queries without wasting time.
