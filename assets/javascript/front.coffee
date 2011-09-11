$ ->
  show = ShowMe "#loading"
  $emailInput = $ "#login-email"
  $loginButton = $ "#login-button"
  $passwordInput = $ "#password-input"
  $regInfoEmail = $ "#registration-info-email"
  $regInfoHandle = $ "#registration-info-handle"
  $regInfoPassword = $ "#registration-info-password"
  emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/

  $.fn.showError = (message) ->
    this.find('.message').text(message).animate {'opacity': 1}, "fast"

  chat = (email, password) ->
    $.post '/session', { email: email, password: password }, ->
      window.location.href = "chat.html";
    .error ->
      $passwordInput.val ''
      $("#enter-password").showError "Wrong password"

  sendEmail = (e) ->
    email = $emailInput.val();
    
    if not email? 
      return
    else if not emailPattern.test email
      $emailInput.val ''
      return $("#login-fields").showError "Invalid email address"

    $.get "/users/#{email}", (user) ->
      if !user.handle
        show "#check-email"
      else
        chatWithPassword = () -> chat user.email, $passwordInput.val()
        $("#enter-password .welcome-name").text user.email
        $("#enter-password .start-chatting-button").click chatWithPassword
        $passwordInput.enter chatWithPassword
        show "#enter-password"
        $passwordInput.focus()

    .error ->
      $.post '/users', { user: { email: $emailInput.val() } }, ->
        show "#check-email"
      .error (xhr) ->
        if  xhr.status is 420
          show "#new-campus"
        else if xhr.status is 403
          $("#login-fields").showError "Please use your .edu email address to verify that you're a student"

        else
          alert "there was an error"

  startChatting = ->
    user = { email: $regInfoEmail.val(), handle: $regInfoHandle.val(), password: $regInfoPassword.val() }
    $.post '/user/' + user.email, { user: user }, ->
      chat user.email, user.password
    .error ->
      alert "there was an error"

  $emailInput.enter(sendEmail).focus()
  $loginButton.click sendEmail
  $("#registration-info .start-chatting-button").click startChatting
  $regInfoEmail.enter startChatting
  $regInfoHandle.enter startChatting
  $regInfoPassword.enter startChatting

  s = window.location.search
  if s
    m = s.match /activation_code=([\w\d]+)$/
    if m?.length > 0
      $.get '/user/activate/' + m[1], (user) -> 
        $("#registration-info-email").val user.email
        show "#registration-info"
      .error ->
        alert "invalid activation code."
    else
      window.location.href = "/404.html"
 
  else
    show "#login-fields"
    $("#login-fields input[type=text]").focus()


  $("#login-fields").showError "Please use your .edu email address to verify that you're a student"
