$(document).ready(function(){
  var localFrameworkVersion = 'compliance'; // 1.1 or 1.2 or compliance or other
  // if you select compliance or other we will add some helpful
  // CSS styling, but you may need to add some CSS yourself
  var newDataProtectionNotificationBanner = document.createElement('script');
  newDataProtectionNotificationBanner.src = 'https://ebi.emblstatic.net/web_guidelines/EBI-Framework/v1.3/js/ebi-global-includes/script/5_ebiFrameworkNotificationBanner.js?legacyRequest='+localFrameworkVersion;
  document.head.appendChild(newDataProtectionNotificationBanner);
  newDataProtectionNotificationBanner.onload = function() {
    ebiFrameworkRunDataProtectionBanner(); // invoke the banner
  };
});
