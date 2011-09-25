$ ->
  show = ShowMe "#loading"
  $emailInput = $ "#login-email"
  $loginButton = $ "#login-button"
  $passwordInput = $ "#password-input"
  $regInfoEmail = $ "#registration-info-email"
  $regInfoHandle = $ "#registration-info-handle"
  $regInfoPassword = $ "#registration-info-password"
  emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/
  doError = (message)-> alert "There was an error:\n\n#{message}"

  $.fn.showError = (message) ->
    this.find('.message').text(message).animate {'opacity': 1}, "fast"

  chat = (email, password) ->
    $.post '/api/session', { email: email, password: password }, (user) ->
      $.get '/' + user.start_room
    .error ->
      $passwordInput.val ''
      $("#enter-password").showError "Wrong password"

  saveRegistration = ->
    user = { email: $regInfoEmail.val(), handle: $regInfoHandle.val(), password: $regInfoPassword.val() }
    $.post '/api/users/' + user.email, { user: user }, ->
      chat user.email, user.password
    .error ->
      doError "there was an error saving registration info"

  sendEmail = (e) ->
    email = $emailInput.val();
    
    if not email? 
      return
    else if not emailPattern.test email
      $emailInput.val ''
      return $("#login-fields").showError "Invalid email address"

    $.get "/api/user/#{email}", (user) ->
      if user.active
        show "#enter-password"

      else if user.voted
        $.get "/api/votes/#{email}", (data) ->
          message = "Once a school reaches 100 votes, we'll open the chat.  "
          if data.count > 1
            message += "So far, #{data.count} others also want to open a chat for your school."
          $("#already-voted .replace-others-for-domain").text message
        .complete ->
          show "#already-voted"
      else
        show "#new-campus"

    .error (xhr)->
      if xhr.status is 404
        $.post '/api/users', { user: { email: $emailInput.val() } }, (data) ->
          show "#new-campus"
        .error (xhr) ->
          switch xhr.status
            when 420 then show "#new-campus"
            when 403 then $("#login-fields").showError "Please use your .edu email address to verify that you're a student"
            else doError "there was an error"
      else
        doError "Could not find user"


  $("#vote-button").click ->
    user = { email: $emailInput.val(), vote_open_on_campus: $("#vote-to-open").is(":checked"), vote_email_me: $("#vote-to-email").is(":checked") }
    $.post "/api/vote/#{user.email}", user, ->
      $.get "/api/votes/#{user.email}", (data) ->
        if data.count > 1
          $("#vote-recorded .replace-others-for-domain").text "#{data.count} others want a Campus Chat for #{data.school}"
      .complete ->
        show "#vote-recorded"
          
    .error ->
      doError "Could not record vote"


  s = window.location.search
  if s
    m = s.match /activation_code=([\w\d]+)$/
    if m?.length > 0
      $.get '/api/users/activate/' + m[1], (user) -> 
        $("#registration-info-email").val user.email
        show "#registration-info"
      .error ->
        doError "invalid activation code."
    else
      window.location.href = "/404.html"
 
  else
    show "#login-fields"
    $("#login-fields input[type=text]").focus()


  $("#registration-info .start-chatting-button").click saveRegistration 
  $emailInput.enter(sendEmail).focus()
  $loginButton.click sendEmail
 
