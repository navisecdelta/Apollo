#!/usr/bin/env ruby

require 'erb'
require 'optparse'
require 'mail'
require 'colorize'
load './identities.rb'

trap "SIGINT" do
  puts "\nBye Bye, thanks for using Apollo by Navisec Delta :)"
  exit 130
end


##################################################################################################
### Parse Arguments

ARGV << '-h' if ARGV.empty?

options = {}
optparse = OptionParser.new do|opts|
    # Set a banner, displayed at the top
    # of the help screen.
    opts.banner = "Usage: Apollo.rb " 
    # Define the options, and what they do

    options[:template] = false
    opts.on( '-t', '--template ', 'Template to be chosen to render emails with' ) do|template|
        options[:template] = template
    end

    options[:email] = false
    opts.on( '-e', '--email ', 'Email to send to victim' ) do|email|
        options[:email] = email
    end

    options[:subject] = false
    opts.on( '-s', '--subject ', 'Subject to send email with' ) do|subject|
        options[:subject] = subject
    end

    options[:identity] = false
    opts.on( '-i', '--identity ', 'Identity to send emails with' ) do|identity|
        options[:identity] = identity
    end


    options[:files] = false
    opts.on( '-f', '--attach ', 'Attach a file, if attaching more than one, comma separate' ) do|files|
        options[:files] = []
        files.split(",").each do |file|
            if File.exist? file
                options[:files].push(Dir.pwd + "/" + file)
            end
        end
    end


    options[:vars] = false
    opts.on( '-V', '--vars ', 'Vars to supply the render with' ) do|vars|
        options[:vars] = {}
        vars.split(",").each do |var_str|
            key = var_str.split("=")[0]
            val = var_str.split("=")[1]
            options[:vars][key] = val
        end
    end

    # This displays the help screen, all programs are
    # assumed to have this option.
    opts.on( '-h', '--help', 'Display this screen' ) do
        puts opts
        exit
    end
end

optparse.parse!

##################################################################################################
### Apollo Class


class Apollo
    attr_accessor :templates, :identity

    def initialize(identity)
        self.templates = {}
        self.identity = identity

        self.get_templates()
    end

    def get_templates()
        template_files = Dir["templates/*.erb"]

        templates = []
        template_files.each do |template|
            self.templates[template.split("/")[1].split(".")[0].capitalize] = template
        end
    end

    def parse_template(chosen_template, data)
        if self.templates.include? chosen_template
            template_raw = File.read(self.templates[chosen_template])

            renderer = ERB.new(template_raw)
            return output = renderer.result(binding)
        else
            puts "We don't have that template!"
        end
    end

    def send_email(subject, to, template, data, attachments=false)
        html = self.parse_template(template, data)

        # I am sorry this is here, it bugs me too. 
        from = self.identity[:from]

        mail = Mail.new do
            from     from
            to       to
            subject  subject
            html_part do
                body     html
                content_type 'text/html; charset=UTF-8'
            end

        end

        if attachments
            attachments.each do |attachment|
                mail.add_file(attachment)
            end
        end

        mail.delivery_method :smtp, self.identity

        delivered_ok = false
        begin
            mail.deliver
        rescue Exception => e
            puts "Error: #{e.to_s}"
        else
            delivered_ok = true
        end

        return delivered_ok
    end

end

##################################################################################################
### Enumerate emails and send emails

if options[:email] and options[:subject] and options[:template] and options[:identity]

    if @identities.include? options[:identity]
        apollo = Apollo.new(@identities[options[:identity]])
    else
        puts "Please specify a valid identity!"
        exit
    end

    if !options[:vars]
        puts "Warning:".red + " there are no vars specified, email formatting may be broken!"
        puts "Use --vars 'key=val,this=that' to specify variables in templates\n\n"
        options[:vars] = ""
    end

    ### Check if supplied argument is a valid file or just an email
    if options[:email].split(",").length == 1 and File.exist? options[:email]
        emails = File.read(options[:email]).split("\n")
    else 
        emails = options[:email].split(',')
    end

    ### Print header of table
    puts "*" + "-" * 61 + "*"
    puts "| #{"Email".ljust(30)}| #{"Delivered".ljust(10)} | #{"Template".ljust(15)}|"
    puts "*" + "-" * 61 + "*"

    ### Enumerate each email and send 
    emails.each do |email|
        res = apollo.send_email(options[:subject], email, options[:template], options[:vars], options[:files])
        puts "| #{email.ljust(30).blue}| #{res.to_s.capitalize.ljust(10)} | #{options[:template].ljust(15).red}|"
        puts "*" + "-" * 61 + "*"
    end

else
    puts "Usage: --help"
end 
