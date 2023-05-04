var frameholder = document.getElementById('frameholder');
var officeFrame = document.createElement('iframe');
officeFrame.name = 'office_frame';
officeFrame.id = 'office_frame';
// The title should be set for accessibility
officeFrame.title = 'Office Online Frame';
// This attribute allows true fullscreen mode in slideshow view
// when using PowerPoint Online's 'view' action.
officeFrame.setAttribute('allowfullscreen', 'true');
// The sandbox attribute is needed to allow automatic redirection to the O365 sign-in page in the business user flow
officeFrame.setAttribute('sandbox',
  'allow-scripts allow-same-origin allow-forms allow-popups allow-top-navigation allow-popups-to-escape-sandbox');
frameholder.appendChild(officeFrame);
document.getElementById('office_form').submit();
