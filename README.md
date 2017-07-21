# TypeBToMail

A simple tool to parse and send type b messages to email.

## Getting Started

In case you have never heard of type b messaging, [this](https://en.wikipedia.org/wiki/Airline_teletype_system) is a good start! In case you do, this tool will help you a lot.

### Prerequisites

You will need the following to have the application running

* A type b client (which supports STX format)
* An email account
* AutoIT

### Installing

1.	Use AutoIT to compile typebtomail.au3 to a windows executable.

2.	Copy all files in a folder. E.g C:\typebtomail

3.	Create 4 folders under the folder described in step 2:

    - PARSED e.g C:\typebtomail\PARSED
    - UNPARSED e.g C:\typebtomail\UNPARSED
    - LOG e.g C:\typebtomail\LOG
    - IN e.g C:\typebtomail\IN

### Configuring

To configure the application you have to edit the configuration.ini accordingly. This is a sample of the configuration.ini:

```
[Directories]
IncomingDir=C:\typebtomail\IN
IncomingDirFilter=*.rcv
LogDir=C:\typebtomail\LOG
ParsedDir=C:\typebtomail\PARSED
UnParsedDir=C:\typebtomail\UNPARSED
[TypeB]
AllowedIdentifiers=MVT,LDM,PSM
SmartParser=1
[MailCommunication]
MailServer=smtp.gmail.com
MailPort=465
MailSSL=1
AccountUsername=your@email.com
AccountPassword=youremailpassword
[MailContent]
Importance=Normal
Destination=theemail@destination.com
CCDestination=thecc@destination.com
BCCDestination=
FromName=My Messaging
FromAddress=theemail@sender.com
```

A description of the elements folows:

Element | Description | Example(s)
--- | --- | --- |
IncomingDir|The folder where incoming type b files are produced from your type b client.|C:\typebtomail\IN
IncomingDirFilter|The wildcard for matching files in IncomingDir. For more information check $sFilter remarks [here](https://www.autoitscript.com/autoit3/docs/libfunctions/_FileListToArray.htm).|*.txt or *.rcv
LogDir|The folder where logs of the applications will be stored.|C:\typebtomail\LOG
ParsedDir|The folder where parsed and transmitted files will be stored.|C:\typebtomail\PARSED
UnParsedDir|The folder where unparsed and not transmitted files will be stored.|C:\typebtomail\UNPARSED
AllowedIdentifiers|The comma delimited message identifiers you want to send to email. If you want all messages to be transmitted, then leave this element blank|MVT,LDM,PSM
SmartParser|A boolean switch for smart removal of headers and subjects before identifier parsing| 1 or 0
MailServer|The host name of ip of your email server|smtp.gmail.com
MailPort|The port of your email server|465
MailSSL|A boolean switch for your email server's SSL|1 or 0
AccountUsername|Your email's account username|georgeroubis@gmail.com
AccountPassword|The password of your email's account|myp@$$w0rd!
Importance|The importance of the transmitted email.|High/Low/Normal
Destination|The email recipient.|someone@gmail.com
CCDestination|The cc recipient.|someoneelse@gmail.com
BCCDestination|The bcc recipient.|ahidden@gmail.com
FromName|The email "From".|MyMessagingSvc
FromAddress|The email "From Address".|georgeroubis@gmail.com

### Running

Run your compliled executable (typebtomail.exe). This can be done directly from windows explorer or from cmd or even from a scheduled task manager tool!

If for example you have received a file called incomingtest.rcv under C:\typebtomail\IN with the following content:

```
=HEADER
RCV,2017/07/21 11:40
=PRIORITY
QK
=DESTINATION TYPE B
STX,TSTXXXX
STX,TSTYYXX
STX,TSTZZXX
=ORIGIN
TSTXXSS
=DBLSIG
XX
=MSGID
123456
=SMI
MVT
=TEXT




XX006/12.SXTST.ATH
ED211140
DL00




```

run the application and you will see something similar to this in the log files:

```
2017-07-21 08:45:41;TypeBToMail.v.1.3.au3;0;1 files were found under directory C:\typebtomail\IN.
*****************************************************************************************************************************
2017-07-21 08:45:41;TypeBToMail.v.1.3.au3;0;Attemtping to read file C:\typebtomail\IN\incomingtest.rcv.
2017-07-21 08:45:41;TypeBToMail.v.1.3.au3;0;File C:\typebtomail\IN\incomingtest.rcv is a valid type b message.
2017-07-21 08:45:41;TypeBToMail.v.1.3.au3;0;File C:\typebtomail\IN\incomingtest.rcv parsed. Data were the following:
                    Received On      -> 2017-07-21 11:40
                    COR Indicator    -> 0
                    PDM Indicator    -> 0
                    Originator       -> TSTXXSS
                    Destination(s)   -> TSTXXXX, TSTYYXX, TSTZZXX
                    Message ID       -> 123456
                    Double Signature -> XX
                    Priority         -> QK
                    Identifier       -> MVT
                    Message Matched  -> Identifier matches system configuration.
                    Text             -> [001] -> MVT
                                        [002] -> XX006/12.SXTST.ATH
                                        [003] -> ED211140
                                        [004] -> DL00
2017-07-21 08:45:41;TypeBToMail.v.1.3.au3;0;Starting email transmission.
2017-07-21 08:45:44;TypeBToMail.v.1.3.au3;0;Email message sent successfully.
2017-07-21 08:45:44;TypeBToMail.v.1.3.au3;0;Attemtping to move file C:\typebtomail\IN\incomingtest.rcv to directory C:\typebtomail\PARSED\2017\07\21.
2017-07-21 08:45:44;TypeBToMail.v.1.3.au3;0;File C:\typebtomail\IN\incomingtest.rcv moved to directory C:\typebtomail\PARSED\2017\07\21.
```


