# Apollo
Apollo is a command-line tool designed specifically for sending spearphishing emails.

A problem I was facing was that using normal email clients, making repeatable emails, juggling multiple accounts and identities was a chore.

That is why we created Apollo.

# Usage

### Examples
```
./Apollo.rb --template Uri --email harry.hack@outlook.com -s "Read this email please." -i john --vars "ip=192.168.1.221,share=share,filename=certificate.docx"
```

Templates are stored in the `templates/` directory, and are in the ERB format. They contain variables that can be replaced on email send.

In the above example, we use the Uri template, we send to harry.hack, 

