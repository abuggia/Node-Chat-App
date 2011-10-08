(function() {
  $(function() {
    var $emailInput, $loginButton, $passwordInput, $regInfoHandle, $regInfoPassword, chat, doError, emailPattern, invites_template, main, render_invites_template, sendEmail, show;
    show = ShowMe("#loading");
    $emailInput = $("#login-email");
    $loginButton = $("#login-button");
    $passwordInput = $("#password-input");
    $regInfoHandle = $("#registration-info-handle");
    $regInfoPassword = $("#registration-info-password");
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
      return $.post('/session', {
        email: email,
        password: password
      }, function() {
        return window.location.href = "chat.html";
      }).error(function() {
        $passwordInput.val('');
        return $("#enter-password").showError("Wrong password");
      });
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
      return $.get("/user/" + email, function(user) {
        if (user.voted) {
          return $.get("/votes/" + email, function(data) {
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
        /*
              if !user.handle
                show "#check-email"
              else
                chatWithPassword = () -> chat user.email, $passwordInput.val()
                $("#enter-password .welcome-name").text user.email
                $("#enter-password .start-chatting-button").click chatWithPassword
                $passwordInput.enter chatWithPassword
                show "#enter-password"
                $passwordInput.focus()
              */
      }).error(function(xhr) {
        if (xhr.status === 404) {
          return $.post('/users', {
            user: {
              email: $emailInput.val()
            }
          }, function(data) {
            return show("#new-campus");
          }).error(function(xhr) {
            switch (xhr.status) {
              case 420:
                return show("#new-campus");
              case 403:
                return $("#login-fields").showError("Please use your .edu email address to verify that you're a student");
              default:
                return doError("there was an error");
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
    /*
        startChatting = ->
        user = { email: $emailInput.val(), handle: $regInfoHandle.val(), password: $regInfoPassword.val() }
        $.post '/user/' + user.email, { user: user }, ->
          chat user.email, user.password
        .error ->
          doError "there was an error"
      */
    main = function() {
      var m, s;
      $emailInput.enter(sendEmail).focus();
      $loginButton.click(sendEmail);
      $("#vote-button").click(function() {
        var user;
        user = {
          email: $emailInput.val(),
          vote_open_on_campus: $("#vote-to-open").is(":checked"),
          vote_email_me: $("#vote-to-email").is(":checked")
        };
        return $.post("/vote/" + user.email, user, function() {
          return $.get("/votes/" + user.email, function(data) {
            if (data.count > 1) {
              $("#vote-recorded .replace-others-for-domain").text("" + data.count + " others want a Campus Chat for " + data.school);
            }
            return render_invites_template(data.count);
          }).complete(function() {
            return show("#vote-recorded");
          });
        }).error(function() {
          return doError("Could not record vote");
        });
      });
      s = window.location.search;
      if (s) {
        m = s.match(/activation_code=([\w\d]+)$/);
        if ((m != null ? m.length : void 0) > 0) {
          return $.get('/user/activate/' + m[1], function(user) {
            $("#registration-info-email").val(user.email);
            return show("#registration-info");
          }).error(function() {
            return doError("invalid activation code.");
          });
        } else {
          return window.location.href = "/404.html";
        }
      } else {
        show("#login-fields");
        return $("#login-fields input[type=text]").focus();
      }
    };
    return main();
  });
}).call(this);
