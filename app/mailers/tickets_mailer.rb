class TicketsMailer < ActionMailer::Base
  default from: "tickets@pintacomex.mx"

  def email_something(someto, somesubject, somebody)
    mail(to: someto,
         subject: somesubject,
         body: somebody)
  end

  def email_something_html(someto, somesubject, somebody)
    mail(to: someto,
         subject: somesubject,
         body: somebody,
         content_type: "text/html")
  end

end
