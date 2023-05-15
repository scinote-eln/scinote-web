(function() {
  const linkedinSignInButton = $('.linkedin-signin-button');
  const hoverSrc = linkedinSignInButton.data('hover-src');
  const defaultSrc = linkedinSignInButton.data('default-src');
  const clickSrc = linkedinSignInButton.data('click-src');

  linkedinSignInButton
    .on('mouseover', () => {
      linkedinSignInButton.attr('src', hoverSrc);
    })
    .on('mouseout', () => {
      linkedinSignInButton.attr('src', defaultSrc);
    })
    .on('click', () => {
      linkedinSignInButton.attr('src', clickSrc);
    });
}());
