---
layout: post
title:  "Mixing React with jQuery"
date: 2016-12-29
categories: guides
tags: react jquery rails javascript
---

For the past two weeks, I've been merrily mixing jQuery into my React components, and I have a few gotchas to share. jQuery certainly needs no introduction, but if you're new to React, check out [Facebook's _excellent_ documentation on it](https://facebook.github.io/react), and try building something with it - it's a peek into the future!

## Why even do that?

Mixing jQuery with React _felt wrong_ when I first considered it. After all, one of the prime purposes of using React is to escape from the spaghetti-code-hell that can arise when creating complex interfaces with lots of different interactions.

The thing is, however, that _that_ hell is not of jQuery's making. So the better question is _why not?_ jQuery is the default JS library available to you if you work with Rails (like I do), and it makes working with JavaScript much easier.

## It's all about the state

The main issue you'll encounter if you add jQuery to a React component is unexpected interactions with React's state-based renderer. In most cases, this means issues with modifications to the DOM, made by jQuery, that React isn't aware of.

### A problematic scenario

Let's take the case of using your friendly neighborhood datepicker inside a component.

```jsx
class ExerciseRecord extends React.Component {
  componentDidMount() {
    $('.js-date-input').myFavDatePicker();
  }

  render() {
    return (
      <form onSubmit={ this.handleSubmit }>
        { this.props.exercises.map(function (exercise, index) {
          return (
            <div>
              <label>{ exercise } done on</label>
              <input className='js-date-input'
                     name={ "dates[" + exercise + "]" }/>
            </div>
          );
        }
        <input type="submit"/>
      </form>
    );
  }
}
```

The problem above is that jQuery code doesn't account for changes made by React, which means that the datepickers are initialized only once. Any modification of `this.props.exercises` (from a parent component) that causes a re-render of this component would introduce new fields without an active datepicker.

### The fix: Extract and control

I see two possible fixes for this situation:

1. The simplest fix would be to use `componentDidUpdate` to initialize datepickers on all updates.
2. Extract the responsibility to a new `DateInput` component.

Repeated initializations could cause issues with the datepicker, so my preferred approach would be to perform an extraction:

```jsx
class DateInput extends React.component {
  componentDidMount() {
    $('.js-date-input-' + this.props.key).myFavDatePicker();
  }

  handleChange() {
    this.setState(date: $(event.target).val());
    // and maybe pass it back up the chain?
  }

  render() {
    return (
      <input className={ 'js-date-input-' + this.props.key }
             onChange={ this.handleChange }/>
    );
  }
}
```

Note how I've used the `key` prop to uniquely identify the input. The `key` can serve another purpose, which I'll discuss in a bit.

## Clean-up after yourself

In the above example, we've created a component to manage creation and updation of the datepicker element. We should go one step further and ensure that the component can also manage its own destruction.

jQuery libraries often modify or introduce new elements into the DOM, which is often placed at the bottom of `<body>`, placing it outside the React container. If the React component is unmounted, this leaves open the very real possibility that it'll leave behind junk in the DOM. Cleaning up after yourself should be simple if the library supports it (most do):

```jsx
class DateInput extends React.component {
  componentWillUnmount() {
    $('.js-date-input-' + this.props.key).myFavDatePicker('destroy');
  }
  ...
}
```

## Using _key_ to regenerate components

In rare cases, direct manipulations of the DOM from jQuery can lead to a situation which renders React unable to update the component. In such situations, it's up to you to alter the `key` prop passed to the component.

Updating `key` instructs React to discard the previous component and create a new one. This gives you a pristine component to work with. In such situations it might be wise to ponder whether a more conventional solution can be had by employing clever(er) coding.

## Communication with the jQuery world outside

If you're like me, then you're probably introducing React components into an existing project (that uses jQuery), instead of building a entirely React-based application. So unless your component is trivial, you'll need a good way to let the jQuery-driven world outside communicate with the React (root) component.

React's [Top Level API](https://facebook.github.io/react/blog/2015/10/01/react-render-and-top-level-api.html) makes this super easy. Use `ReactDOM.render` to create or update existing components, and `ReactDOM.unmountComponentAtNode` to destroy existing ones.

Whichever you pick, **do not** do what I did the first time; `$('.react-container'').html('')` will leave behind loaded React components in memory. Ouch.

## Server-side rendering is a no-go

A lot of jQuery code simply won't execute without `window` being available - which it isn't on the server. So if you want to render server-side you'll have to avoid using jQuery for initial render of all components, which can be pretty tricky.

## Wrap-up

The bottom line is that jQuery is beloved by many, and if using jQuery makes adopting React more palatable then by all means, mix and enjoy. But as the saying goes, _enjoy responsibly_ - keeping the quirks and drawbacks in mind will let you combine the best of both worlds. Cheers!
