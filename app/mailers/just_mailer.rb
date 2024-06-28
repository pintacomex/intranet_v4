#!/bin/env ruby
# encoding: utf-8

class JustMailer < ActionMailer::Base
  default from: "no-responder@serviciofacturacion.mx"

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
