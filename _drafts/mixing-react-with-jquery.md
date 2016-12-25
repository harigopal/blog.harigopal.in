---
layout: post
title:  "Mixing React with jQuery"
date: 2016-12-22
categories: react jquery
---

For the past two weeks, I've been merrily mixing jQuery into my React components, and I have a few gotchas to share. jQuery certainly needs no introduction, but if you're new to React, check out [Facebook's _excellent_ documentation on it](https://facebook.github.io/react), and try building something with it - it's a peek into the future!

## Why even do that?

Mixing jQuery with React _felt wrong_ when I first considered it. After all, one of the prime purposes of using React is to escape from the spaghetti-code-hell that can arise when creating complex interfaces with lots of different interactions.

The thing is, however, that _that_ hell is not of jQuery's making. So the better question is _why not?_ jQuery is the default JS library available to you if you work with Rails (like I do), and it makes working with JavaScript much easier.
 
## It's all about the state

The main issue you'll encounter if you add jQuery to a React component is unexpected interactions with React's state-based renderer. In most cases, this means issues with modifications to the DOM, made by jQuery, that React isn't aware of.
g
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
  onComponentDidMount() {
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

Note how I've used the `key` prop to uniquely identify the input. The `key` can serve another purpose, which bring me to...

## Use _key_ to regenerate components

TODO: Describe how React's `key` prop can be leveraged to discard messed up components and generated anew when jQuery does something that messes up a component.

## Communication with the jQuery world outside

If you're like me, then you're probably introducing React components into an existing project (that uses jQuery), instead of building a entirely React-based application. In this case, you'll need a good way to manage communication between your React (root) component and the jQuery-driven code outside of it.

TODO: Write about `ReactDOM` and manually triggering ReactUJS's mount Refer https://facebook.github.io/react/docs/react-dom.html

## Server-side rendering is a no-go

React components with jQuery inside render server-side (TODO: Confirm this)- there's no `window` for it to interact with.

## Wrap-up

The bottom line is that jQuery is beloved by many, and if using jQuery makes adopting React more palatable then by all means, mix and enjoy. But as the saying goes, _enjoy responsibly_ - keeping the quirks and drawbacks in mind will let you combine the best of both worlds.
