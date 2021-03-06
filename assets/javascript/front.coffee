$ ->
  show = ShowMe "#loading"
  $emailInput = $ "#login-email"
  $loginButton = $ "#login-button"
  $passwordInput = $ "#password-input"
  emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/
  doError = (message)-> alert "There was an error:\n\n#{message}"

  $.fn.showError = (message) ->
    this.find('.message').text(message).animate {'opacity': 1}, "fast"

  chat = (email, password) ->
    $.post '/api/session', { email: email, password: password }, (user) ->
      window.location.href = '/' + user.start_room
    .error ->
      $passwordInput.val ''
      $("#enter-password").showError "Incorrect Password"

  saveRegistration = ->
    user = { email: $$("#registration-info-email").val(), handle: $("#registration-info-handle").val(), password: $("#registration-info-password").val(), agreed_to_tos: $('#agree-to-terms-of-service').is(':checked') }
 

    if user.handle.length < 2
      alert 'chat username must be at least 2 characters'
    else if user.password.length < 5
      alert 'Password must be at least 5 characters'
    else if not user.agreed_to_tos
      alert 'To use CampusChat, you must agree to our terms of service'
    else
      $.post '/api/users/' + user.email, { user: user }, ->
        chat user.email, user.password
      .error (e) ->
        if e.status is 409
          alert 'This username has been taken.  Please choose a different one.'
        else
          doError "there was an error saving registration info"

  signUpOrSignIn = (user) ->
    if user.active
      if not user.handle
        $$("#registration-info-email").val(user.email)
        show "#registration-info"
      else
        show "#enter-password"
        $passwordInput.focus()

    #else 
    #  $.get "/api/user/#{user.email}/checkschool", ()

    else if user.voted
      $.get "/api/votes/#{user.email}", (data) ->
        message = "Once a school reaches 100 votes, we'll open the chat.  "
        if data.count > 1
          message += "So far, #{data.count} others also want to open a chat for your school."
            
        $("#already-voted .replace-others-for-domain").text message 
        render_invites_template data.count
          
      .complete ->
        show "#already-voted"
    else
      show "#new-campus"


  sendEmail = (e) ->
    email = $emailInput.val();
    
    if not email? 
      return
    else if not emailPattern.test email
      $emailInput.val ''
      return $("#login-fields").showError "Invalid email address"

    $.get "/api/user/#{email}", (user) ->
      signUpOrSignIn(user)

    .error (xhr)->
      if xhr.status is 404
        $.post '/api/users', { user: { email: $emailInput.val() } }, (user) ->
          signUpOrSignIn(user)
        .error (xhr) ->
          switch xhr.status
            when 420 then show "#new-campus"
            when 403 then $("#login-fields").showError "Please use your .edu email address to verify that you're a student"
            else doError "there was an error sending email"
      else
        doError "Could not find user"

  
  render_invites_template = (votes) ->
    text = "#{votes} others and I want to have a chat opened for my campus, submit your vote by logging in at http://campusch.at @campusch_at"
    text = escape text
    $(".invite_links").html invites_template(text)

  invites_template = (text) ->
    "Invite your friends to vote via 
    <a target='_blank' id='facebook-link' href='http://www.facebook.com/sharer/sharer.php?u=http://campusch.at&t=#{text}'>
      Facebook</a>
    and 
    <a target='_blank' id='twitter-link' href='http://twitter.com/intent/tweet?text=#{text}'>
    Twitter</a>!"

  main = ->
    $("#registration-info .start-chatting-button").click saveRegistration 
    $emailInput.enter(sendEmail).blur()
    $loginButton.click(sendEmail)
    $("#enter-password .start-chatting-button").click -> chat($emailInput.val(), $passwordInput.val())
    $passwordInput.enter -> chat($emailInput.val(), $passwordInput.val())
 
    $("#vote-button").click ->
      user = { email: $emailInput.val(), vote_open_on_campus: $("#vote-to-open").is(":checked"), vote_email_me: $("#vote-to-email").is(":checked") }
      $.post "/api/vote/#{user.email}", user, ->
        $.get "/api/votes/#{user.email}", (data) ->
          if data.count > 1
            $("#vote-recorded .replace-others-for-domain").text "#{data.count} others want a Campus Chat for #{data.school}"
            render_invites_template data.count
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


  main()


