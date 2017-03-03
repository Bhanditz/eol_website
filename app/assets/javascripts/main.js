if(!EOL) {
  var EOL = {};
  EOL.allow_meta_traits_to_toggle = function() {
    $(".toggle_meta").on("click", function (event) {
      event.stopPropagation();
      var $table = $(this).next();
      $table.toggle();
      if ($table.is(":visible")) {
        var $node = $(this).closest("tr");
        $($('html,body')).unbind().animate({scrollTop: $node.offset().top - 50}, 400);
      }
    });
    $(".meta_trait").hide();
  };

  EOL.initialize = function() {
    angular.bootstrap(document.body, ['eolApp']);
    if($(".galleria").length) {
      Galleria.loadTheme("/assets/galleria/themes/classic/galleria.classic.min.js");
      Galleria.run(".galleria");
    }
    EOL.allow_meta_traits_to_toggle();
  };
}

(function () {
  'use strict';
  // These depend on devise configurations. DON'T FORGET TO CHANGE IT when you
  // change in devise.rb
  var passwordMinLength = 8;
  var passwordMaxLength = 32;

  var app = angular
    .module("eolApp", ["ngAnimate", "ngMaterial", "ngSanitize"])
    .config(function($mdThemingProvider) {
      $mdThemingProvider.theme('default')
        .primaryPalette('brown', {
          'default': '800'
        })
        .accentPalette('indigo', {
          'default': '800'
        });
    });

  // You have to reload the app's JS in a few cases:
  $(document).on("turbolinks:load", function() { EOL.initialize(); });
  //TODO: this doesn't work... was attempting to fix the initialize of the site when you click the back button.
  // $(document).on("page:restore", function() { EOL.initialize(); });

  app.controller("SearchCtrl", SearchCtrl);
  app.controller("CladeFilterCtrl", CladeFilterCtrl);
  app.controller("collectionSearchCtrl", collectionSearchCtrl);
  app.controller("PageCtrl", PageCtrl);
  app.controller("loginValidate", LoginCtrl);
  app.controller('signupValidate', SignupCtrl);
  app.controller('ConfirmDeleteCtrl', ConfirmDeleteCtrl);

  function SearchCtrl ($scope, $http, $window) {
    $scope.selected = undefined;

    $scope.querySearch = function(query) {
      return $http.get("/search.json", {
        params: { q: query + "*", per_page: "6", only: "pages" }
      }).then(function(response){
        var data = response.data;
        $.each(data, function(i, match) {
          var re = new RegExp(query, "i");

          match.names = [];
          if(match.scientific_name.match(re)) {
            match.names.push({ string: match.scientific_name, language: { code: "sci" } });
          };
          $.each(match.preferred_vernaculars, function(j, vmatch) {
            if(vmatch.string.match(re)) {
              match.names.push(vmatch);
            };
          });
        });
        console.log("Matches:");
        console.log(data);
        return data;
      });
    };

    $scope.onSelect = function($item, $model, $label) {
      if (typeof $item !== 'undefined') {
        $scope.selected = $item.scientific_name;
        $window.location = "/pages/" + $model.id;
      }
    };

    $scope.nameOfModel = function($model) {
      if (typeof $item === 'undefined') {
        return "";
      } else {
        return $model.scientific_name.replace(/<\/?i>/g, "");
      }
    };
  }

  function CladeFilterCtrl ($scope, $http, $window) {
	$scope.cladeFilter = function(clade_name, uri) {
		return $http.get("/clade_filter.js", {
       		params: { clade_name: clade_name, uri: uri }
    	}).then(function(response, $compile){
    		var elem = angular.element("div#traits_table");
    		$compile = elem.injector().get('$compile');
    		var scope = elem.scope();
    		elem.html( $compile(response.data)(scope) );
		});
  	};
  }

  function collectionSearchCtrl ($scope, $http) {
    $scope.selected = undefined;
    $scope.showClearSearch = false;

    $scope.querySearch = function(query, collection_id) {
      return $http.get("/collected_pages/search.json", {
        params: { q: query + "*", collection_id: collection_id }
      }).then(function(response) {
        var data = response.data;
        if(data.length > 0){
          $.each(data, function(i, match) {
            var re = new RegExp(query, "i");
            match.names = [];
            // TODO: this is ALSO broken (see first querySearch above) Ideally,
            // this would be an abstracted method that we used in both places.
            // Quick note: probably better to abstract the inner then() call,
            // since the rest isn't duplicated.
            if(match.scientific_name.match(re)) {
              match.names += { string: match.scientific_name };
            };
            match.names =
              jQuery.grep(match.preferred_vernaculars, function(e) {
                return e.string.match(re);
              });
          });
        } else {
          data =  [{names: {string: "No pages found!" }}];
        }
        return data;
      });
    };

    $scope.onSelect = function($item, $model, $label, collection_id) {
      if (typeof $item !== 'undefined') {
        if(typeof $scope.selectedPage.names[0] === 'undefined') return;
        $scope.name = $scope.selectedPage.names[0].string;
        $scope.selected = $item.scientific_name;
        $("div.collected_pages").hide();
        $http.get("/collected_pages/search_results" , {
        params: { q: $scope.name, collection_id: collection_id}
      }).then(function(response){
        var data = response.data;
        document.querySelector('div.search_results').innerHTML= response.data;
        $scope.showClearSearch = true;
        return data;
      });
      }
    };

    $scope.nameOfModel = function($model) {
      if (typeof $item === 'undefined') {
        return "";
      } else {
        return $model.scientific_name.replace(/<\/?i>/g, "");
      }
    };

    $scope.clearSearch = function() {
      $("div.collected_pages").hide();
      $('div.search_results').remove();
      $scope.showClearSearch = false;
    };
  }

  function PageCtrl ($scope, $http) {
    $scope.testVar = "foo";
    $scope.traitsCollapsed = false;
    $scope.isCollapsed = false;
  }

  function LoginCtrl ($scope, $window) {
    $scope.recaptchaChecked = ($(".g-recaptcha").length === 0);
    $scope.recaptchaError = false;
    $scope.showErrors = false;

    $scope.validateForm = function(event, loginForm) {
      if (loginForm.$invalid) {
        $scope.showErrors = true;
        event.preventDefault();
      }
      if (typeof(grecaptcha) !== 'undefined') {
        var recaptchaResponse = grecaptcha.getResponse();
        if (grecaptcha.getResponse() !== undefined &&
          (grecaptcha.getResponse() === null) ||
          (grecaptcha.getResponse() === '')) {
          $scope.showErrors = true;
          $scope.recaptchaError = $window.recaptchaError = true;
          event.preventDefault();
        }
        else
        {
           $scope.recaptchaError = false;
           $scope.recaptchaChecked = true;
        }
      }
    };
  }

  // fix the autofill problem in password fields
  app.directive('autofill', function () {
	    return {
	        require: 'ngModel',
	        link: function (scope, element, attrs, ngModel) {
	            scope.$watch(function () {
	              return element.val();
	            }, function(nv, ov) {
	              if(nv !== ov)
	                ngModel.$setViewValue(nv);
	            });
	        }
	    };
	});

  //custom validation for password match
  app.directive('passwordMatch', function () {
  	return {
  		require: 'ngModel',
  		link: function (scope, element, attrs, ctrl) {
  			var firstPassword = '#' + attrs.passwordMatch;
  			$(element).add(firstPassword).on('keyup', function () {
  				scope.$apply(function () {
  					ctrl.$setValidity('pwmismatch', element.val() === $(firstPassword).val());
  				});
  			});
  		}
  	};
  });

  //custom validation for password match
  app.directive('validatePassword', function () {
  	return {
  		require: 'ngModel',
  		link: function (scope, element, attrs, ctrl) {
  			ctrl.$parsers.unshift(function(viewValue) {
  				scope.violatePwdLowerLimit = (viewValue && viewValue.length < passwordMinLength ? true : false);
  				scope.violatePwdUpperLimit = (viewValue && viewValue.length > passwordMaxLength ? true : false);
  				if (!(scope.violatePwdLowerLimit || scope.violatePwdUpperLimit)){
  					scope.ViolatepwdLetterCond = (viewValue && /[A-Za-z]/.test(viewValue)) ? false : true;
  					scope.ViolatepwdNumberCond = (viewValue && /\d/.test(viewValue)) ? false : true;
  				}

  				if (scope.violatePwdLowerLimit && scope.violatePwdUpperLimit && scope.ViolatepwdLetterCond && scope.ViolatepwdNumberCond){
  					ctrl.$setValidity('pwd', false);
  					return viewValue;
  				} else {
  					ctrl.$setValidity('pwd', true);
  					return viewValue;
  				}
  			});
  		}
  	};
  });

  function SignupCtrl ($scope, $window) {
      $scope.showErrors = false;
      $scope.recaptchaChecked = ($(".g-recaptcha").length === 0);
      $scope.recaptchaError = false;
      $scope.validateForm = function(event, signupForm) {
          if (signupForm.$invalid) {
              $scope.showErrors = true;
              event.preventDefault();
          }
          if (!(typeof grecaptcha === 'undefined')) {
              var recaptchaResponse = grecaptcha.getResponse();
              if (grecaptcha.getResponse() != undefined &&
                  (grecaptcha.getResponse() === null) ||
                  (grecaptcha.getResponse() === '')) {
  	                $scope.showErrors = true;
  	                $scope.recaptchaError = $window.recaptchaError = true;
  	                event.preventDefault();
              }
              else
              {
                  recaptchaError = false;
              }
          }
      };
  }

  function ConfirmDeleteCtrl ($scope, $mdDialog, $mdMedia, $http, $window){
  	   $scope.showConfirm = function(ev,user_id, msg) {
  	    var confirm = $mdDialog.confirm()
        .textContent(msg)
        .targetEvent(ev)
        .ok('ok')
        .cancel('cancel');
        $mdDialog.show(confirm).then(function() {
          $http({
            method : 'POST',
            url :'/users/delete_user?id=' + user_id.toString()
           }).then(
             function mySucces(response){
               console.log("The response"+ response);
               $window.location.href = "http://"+ $window.location.host;
           });
        });
  	   };
  }

  $(".pops.up").popup();
}());

var recaptchaError = false;

function recaptchaCallback() {
  console.log("recaptchaCallback()");
  var appElement = $(".recaptchad")[0];
  var $scope = angular.element(appElement).scope();
  $scope.$apply(function() {
    $scope.recaptchaError = false;
    $scope.recaptchaChecked = true;
  });
}
