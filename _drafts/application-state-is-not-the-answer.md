---
layout: post
title: "Application State is not the answer"
categories: guides
tags: react reasonreact
---

So...

This is a total retraction of my last two posts.

## Mistakes were made

Using application state, or global state is _not_ right the answer for most developers of front-end components.

The draw of application state is the creation of a _definitive_ single-source of truth from which our entire app's state can be determined. Then, this _definitive_ state becomes the one and _only_ place where you need to _query_ state. And because it is ubiquitous, adding a new shared property becomes extremely simple; add it once, and it's available everywhere.

This ease of modification is, unfortunately, double-edged. I've noticed two (messy) patterns arise once global state is available.

### There is no _local_; everything is _global_

The lure of global state is such that once it is implemented, it has a tendency to _supplant_ local state management. Simple UI changes that could have been implemented as local state changes creep into global state because their values _could_ be used to affect other components in _cool_ ways.

Here's a simple example of this: On _Turaku_ (my _late_ pet password manager project), editing the title of any _entry_ using the _editor_ component changes the title of the entry in the _entries list_ component immediately. This was extremely easy to implement because the two components shared the data about entries via the application state.

{{ '201910/turaku-editing-entry-title.gif' | image_from_cdn:'Editing title of an entry in Turaku' }}

The drawback is that even though the responsibility for _changing_ an entry lies logically with the editor component, something as simple as _saving_ changes becomes a sticky proposition. Questions arise:

- What happens if the user clicks on another entry in the list when one has unsaved changes? Sure, the unsaved changes would persist - they're in app state, but the old editor would be unmounted eventually...
- So which part of the UI should the user interact with to initiate the save?
- Maybe we should auto-save if the editor un-mounts as a result of user switching to another view..? But which part of the UI would show that there is a network operation on-going? What happens if the network operation fails?

The last option is what I went with, and I never answered all of the questions fully. I just slapped a few chunks of code together to get everything working, and promised myself that I would get around to cleaning it up eventually.

This was me ignoring the _KISS_ principle.

What should have been simple - making a few edits to an entry, and then saving it ended up involving _many_ different components, and is now  unnecessarily complicated because I couldn't say &ldquo;No&rdquo; to a few cool things.

### Application state is god; all responsibilities are centralised

I think that [SRP](https://en.wikipedia.org/wiki/Single_responsibility_principle) is more of a _guideline_ than a _rule_ when it comes to writing applications, but by its very nature, application state seems _require_ that SRP be _broken_.

When we collect state from different parts of the application, it's almost impossible for all of these values to be (closely) related. Usually, they're collected over time as the application's feature-set expands and evolves, and as such they're going to be incorporated into a single reducer that, increasingly needs to handle values with different purposes.

The issue that pops up as a result is increased _cognitive load_. It's easy to make changes when the number of things that _can_ change is low. The larger the size of the state being managed by a reducer, the harder it is to simply fit all of its variables into _our_ working memory.

## Back to Basics

When reaching for global / application state as a solution from our toolbox, its critical to examine whether it's worth the costs involved, and whether we're being careful to avoid the pitfalls that it exposes.

State-management based on localized state with plentiful prop drilling is definitely _not_ stylish, but it's based on sound development practises, works _really_ well in most situations, and should be the default choice for React and ReasonReact applications of any level of complexity.

As for my pet project, it's future is uncertain. I made a _lot_ of mistakes in that codebase, while learning to use ReasonML and ReasonReact for the first time. It's state management is, quite frankly, a mess. However, thanks to those mistakes, by the time I introduced ReasonML & ReasonReact to my full-time work, I knew enough to be conservative.

Right now, I'm focusing on building [PupilFirst](https://www.pupilfirst.com) - an LMS that my company open-sourced recently, and which we've been working on since 2013. It mixes Ruby, ReasonML & GraphQL, and is probably one of the largest open-source ReasonReact webapps out there.