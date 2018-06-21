# SciNote Developers Documentation

## Front-end (React.js)

### Validations

**Validation components**

Whenever you have a pretty generic form, use the validation components on the front-end and back-end.

An example use case for how to handle this new validation can be seen on New Team page. The validators are merely a single-input-field validators, and can only get you so far. For more complex validation (e.g. whether password & password confirmation match), server-side validation should be used.

The validation is run by providing the same `tag` property to various elements that relate to the same "data field", as well as hooking the relevant validators to the `<InputFormControl>`, and voila - the validation magically works :rainbow:!

Also the `<ValidatedSubmitButton>` is automatically disabled as soon as there is any error on the form.

To call the form itself from within the hosting component, you should use the `ref` mechanism:

```javascript
<ValidatedForm ref={(f) => { this.myForm = f; }}>
```

Additional validators can be added once we need them. They are basically a Javascript function that receives `target` (input element reference) and `messageIds`, and returns an array of errors (which are a JSON object which support localization). This will be better once we onboard flow onto them.

**How to render server errors?**

If the server returns any error (this excludes actual validation errors, mostly related to the input data being incorrect), ideally we want to display this (e.g. `Oops, something went wrong!` or similar) by one of 2 means:

* if it's a form, display it as a general form error feedback;
* if NOT a form, display it in a flash message (if this is the case and the error occurred in modal window, modal **MUST** be closed, because otherwise flash message isn't really seen by the user properly).