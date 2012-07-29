(function() {

  $(function() {
    var $emailInput, $loginButton, $passwordInput, chat, doError, emailPattern, invites_template, m, main, render_invites_template, s, saveRegistration, sendEmail, show, signUpOrSignIn;
    show = ShowMe("#loading");
    $emailInput = $("#login-email");
    $loginButton = $("#login-button");
    $passwordInput = $("#password-input");
    emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
    doError = function(message) {
      return alert("There was an error:\n\n" + message);
    };
    $.fn.showError = function(message) {
      return this.find('.message').text(message).animate({
        'opacity': 1
      }, "fast");
    };
    chat = function(email, password) {
      return $.post('/api/session', {
        email: email,
        password: password
      }, function(user) {
        return window.location.href = '/' + user.start_room;
      }).error(function() {
        $passwordInput.val('');
        return $("#enter-password").showError("Incorrect Password");
      });
    };
    saveRegistration = function() {
      var user;
      user = {
        email: $$("#registration-info-email").val(),
        handle: $("#registration-info-handle").val(),
        password: $("#registration-info-password").val(),
        agreed_to_tos: $('#agree-to-terms-of-service').is(':checked')
      };
      if (user.handle.length < 2) {
        return alert('chat username must be at least 2 characters');
      } else if (user.password.length < 5) {
        return alert('Password must be at least 5 characters');
      } else if (!user.agreed_to_tos) {
        return alert('To use CampusChat, you must agree to our terms of service');
      } else {
        return $.post('/api/users/' + user.email, {
          user: user
        }, function() {
          return chat(user.email, user.password);
        }).error(function(e) {
          if (e.status === 409) {
            return alert('This username has been taken.  Please choose a different one.');
          } else {
            return doError("there was an error saving registration info");
          }
        });
      }
    };
    signUpOrSignIn = function(user) {
      if (user.active) {
        if (!user.handle) {
          $$("#registration-info-email").val(user.email);
          return show("#registration-info");
        } else {
          show("#enter-password");
          return $passwordInput.focus();
        }
      } else if (user.voted) {
        return $.get("/api/votes/" + user.email, function(data) {
          var message;
          message = "Once a school reaches 100 votes, we'll open the chat.  ";
          if (data.count > 1) {
            message += "So far, " + data.count + " others also want to open a chat for your school.";
          }
          $("#already-voted .replace-others-for-domain").text(message);
          return render_invites_template(data.count);
        }).complete(function() {
          return show("#already-voted");
        });
      } else {
        return show("#new-campus");
      }
    };
    sendEmail = function(e) {
      var email;
      email = $emailInput.val();
      if (!(email != null)) {
        return;
      } else if (!emailPattern.test(email)) {
        $emailInput.val('');
        return $("#login-fields").showError("Invalid email address");
      }
      return $.get("/api/user/" + email, function(user) {
        return signUpOrSignIn(user);
      }).error(function(xhr) {
        if (xhr.status === 404) {
          return $.post('/api/users', {
            user: {
              email: $emailInput.val()
            }
          }, function(user) {
            return signUpOrSignIn(user);
          }).error(function(xhr) {
            switch (xhr.status) {
              case 420:
                return show("#new-campus");
              case 403:
                return $("#login-fields").showError("Please use your .edu email address to verify that you're a student");
              default:
                return doError("there was an error sending email");
            }
          });
        } else {
          return doError("Could not find user");
        }
      });
    };
    render_invites_template = function(votes) {
      var text;
      text = "" + votes + " others and I want to have a chat opened for my campus, submit your vote by logging in at http://campusch.at @campusch_at";
      text = escape(text);
      return $(".invite_links").html(invites_template(text));
    };
    invites_template = function(text) {
      return "Invite your friends to vote via     <a target='_blank' id='facebook-link' href='http://www.facebook.com/sharer/sharer.php?u=http://campusch.at&t=" + text + "'>      Facebook</a>    and     <a target='_blank' id='twitter-link' href='http://twitter.com/intent/tweet?text=" + text + "'>    Twitter</a>!";
    };
    main = function() {
      $("#registration-info .start-chatting-button").click(saveRegistration);
      $emailInput.enter(sendEmail).blur();
      $loginButton.click(sendEmail);
      $("#enter-password .start-chatting-button").click(function() {
        return chat($emailInput.val(), $passwordInput.val());
      });
      $passwordInput.enter(function() {
        return chat($emailInput.val(), $passwordInput.val());
      });
      return $("#vote-button").click(function() {
        var user;
        user = {
          email: $emailInput.val(),
          vote_open_on_campus: $("#vote-to-open").is(":checked"),
          vote_email_me: $("#vote-to-email").is(":checked")
        };
        return $.post("/api/vote/" + user.email, user, function() {
          return $.get("/api/votes/" + user.email, function(data) {
            if (data.count > 1) {
              $("#vote-recorded .replace-others-for-domain").text("" + data.count + " others want a Campus Chat for " + data.school);
              return render_invites_template(data.count);
            }
          }).complete(function() {
            return show("#vote-recorded");
          });
        }).error(function() {
          return doError("Could not record vote");
        });
      });
    };
    s = window.location.search;
    if (s) {
      m = s.match(/activation_code=([\w\d]+)$/);
      if ((m != null ? m.length : void 0) > 0) {
        $.get('/api/users/activate/' + m[1], function(user) {
          $("#registration-info-email").val(user.email);
          return show("#registration-info");
        }).error(function() {
          return doError("invalid activation code.");
        });
      } else {
        window.location.href = "/404.html";
      }
    } else {
      show("#login-fields");
      $("#login-fields input[type=text]").focus();
    }
    return main();
  });

}).call(this);
