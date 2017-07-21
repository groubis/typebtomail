#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.1
 Author:         George Roubis

 Script Function:
	Reads type b messages, parses them, filters them and sends them to an email
	Error codes:	1 	- > Normal Operation - Warning
					0 	- > Normal Operation
					2	- > Configuration Error
					100 - > General Error
					200 - > Email transmission error

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
   #include <file.au3>
   #include <array.au3>
   #include <date.au3>
   #include "_INetSmtpMailCom.au3"
   #include "_WM_Date_Generate_UTC_DateTime.au3"

	;Declare the ini file with default values
	$INI_File = @ScriptDir&'\configuration.ini'

	;If the ini file was not found
	If FileExists($INI_File) = 0 Then

		;Set message
		$Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";2;Unable to find configuration.ini."

		;Notify
		consolewrite($Message&@CRLF)

		;Log
		FileWriteLine("ERROR.LOG",$Message)

		;Exit
		Exit

	EndIf

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;Read ini file configuration                                   ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;Get the path where incoming files are placed
	$IncomingPath			=	IniRead ( $INI_File, "Directories", "IncomingDir", "" )

	;Get the filter of $IncomingPath
	$IncomingFilesFilter	=	IniRead ( $INI_File, "Directories", "IncomingDirFilter", "" )

	;Get the path where unparsed files will be placed
	$UnparsedPath			=	IniRead ( $INI_File, "Directories", "UnParsedDir", "" )

	;Get the path where unparsed files will be placed
	$ParsedPath				=	IniRead ( $INI_File, "Directories", "ParsedDir", "" )

	;Get the path where log files will be generated
	$LogPath				=	IniRead ( $INI_File, "Directories", "LogDir", "" )

	;Dynamically generate the current log file
	$LogFile				=	$LogPath&'\'&_WM_Date_Generate_UTC_DateTime("YEAR")&'\'&_WM_Date_Generate_UTC_DateTime("MON")&'\'&_WM_Date_Generate_UTC_DateTime("YEAR")&'.'&_WM_Date_Generate_UTC_DateTime("MON")&'.'&_WM_Date_Generate_UTC_DateTime("DAY")&'.txt'

	;Get the smart parser switch value
	$SmartParser			=	IniRead ( $INI_File, "TypeB", "SmartParser", "" )

    ;Get the allowed identifiers
    $AllowedIdentifiers 	= 	IniRead ( $INI_File, "TypeB", "AllowedIdentifiers","")

    ;Convert the allowed identifiers to an array
    $AllowedIdentifiersArray= 	StringSplit($AllowedIdentifiers,",")

	;If allowed identifiers are blank
	If StringStripWS($AllowedIdentifiers,8) = "" Then

	  ;set all allowed to on
	  $AllowAllIdentifiers	=	1

    Else

	  ;set all allowed to off
	  $AllowAllIdentifiers  = 	0

    EndIf

	;Get Mail Server
	$MailServer				=	IniRead ( $INI_File, "MailCommunication", "MailServer","")

	;Get Mail Server Port
	$MailPort				=	IniRead ( $INI_File, "MailCommunication", "MailPort","")

	;Get Mail Server SSL option
	$MailSSL				=	IniRead ( $INI_File, "MailCommunication", "MailSSL","")

	;Get Mail Username
	$MailUsername			=	IniRead ( $INI_File, "MailCommunication", "AccountUsername","")

	;Get Mail Password
	$MailPassword			=	IniRead ( $INI_File, "MailCommunication", "AccountPassword","")

	;Get Mail Importance
	$MailImportance			=	IniRead ( $INI_File, "MailContent", "Importance","")

	;Get the mail destination
	$MailDestination		=	IniRead ( $INI_File, "MailContent", "Destination","")

	;Get the mail cc destination
	$MailCCDestination		=	IniRead ( $INI_File, "MailContent", "CCDestination","")

	;Get the mail bcc destination
	$MailBCCDestination		=	IniRead ( $INI_File, "MailContent", "BCCDestination","")

	;Get from name
	$MailFromName			=	IniRead ( $INI_File, "MailContent", "FromName","")

	;Get from address
	$MailFromAddress		=	IniRead ( $INI_File, "MailContent", "FromAddress","")


	If Not FileExists($LogFile) Then

		;Create the log File
		If Not _FileCreate($LogFile) Then

			;Set message
			$Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";100;Unable to create log file '"&$LogFile&"'."

			;Notify
			consolewrite($Message&@CRLF)

			;Exit
			Exit

		EndIf

	EndIf


   ;Store files to an array
   Local $CurrentWorkingPathFileList = _FileListToArray($IncomingPath, $IncomingFilesFilter, 1, 1)

   ;Folder not found or invalid
   If @error = 1 Then

	  ;Set message
	  $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";100;Path "&$IncomingPath&' is invalid or does not exist.'

	  ;Notify
	  consolewrite($Message&@CRLF)

	  ;Log
	  FileWriteLine($LogFile,$Message)

   ;Invalid $sFilter
   ElseIf @error = 2 Then

	  ;Set message
	  $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&"100;Filter "&$IncomingFilesFilter&" applied on path "&$IncomingPath&' is invalid.'

	  ;Notify
	  consolewrite($Message&@CRLF)

	  ;Log
	  FileWriteLine($LogFile,$Message)

   ;Invalid $iFlag
   ElseIf @error = 3 Then

	  ;Set message
	  $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";200;File flag applied on _FileListToArray for path "&$IncomingPath&' is invalid. This error requires core modules code inspection.'

	  ;Notify
	  consolewrite($Message&@CRLF)

	  ;Log
	  FileWriteLine($LogFile,$Message)

   ;No File(s) Found
   ElseIf @error = 4 Then

	  ;Set message
	  $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";1;No files were found under directory "&$IncomingPath&'.'

	  ;Notify
	  consolewrite($Message&@CRLF)

	  ;Log
	  FileWriteLine($LogFile,$Message)

   Else

	  ;Set message
	  $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";0;"&$CurrentWorkingPathFileList[0]&" files were found under directory "&$IncomingPath&'.'

	  ;Notify
	  consolewrite($Message&@CRLF)

	  ;Log
	  FileWriteLine($LogFile,$Message)

	  ;Loop through files
	  For $i = 1 To $CurrentWorkingPathFileList[0]


		 ;Set message
		 $Message = "*****************************************************************************************************************************"

		 ;Notify
		 consolewrite($Message&@CRLF)

		 ;Log
		 FileWriteLine($LogFile,$Message)

		 ;File empty Switch
		 $FILE_IS_EMPTY		=	0

		 ;File processed Switch
		 $FILE_IS_VALID	=	0

		 ;Set current working file
		 $CurrentWorkingFile	=	$CurrentWorkingPathFileList[$i]

		 ;Convert the path to an array to get only the file name
		 $TempFileNameArray	=	StringSplit($CurrentWorkingFile,"\")

		 ;Get the file name
		 $CurrentWorkingFileName	=	$TempFileNameArray[$TempFileNameArray[0]]

		 ;Set message
		 $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";0;Attemtping to read file "&$CurrentWorkingFile&"."

		 ;Notify
		 consolewrite($Message&@CRLF)

		 ;Log
		 FileWriteLine($LogFile,$Message)

		 ; Open the file for reading and store the handle to a variable.
		 Local $CurrentWorkingFileOpen = FileOpen($CurrentWorkingFile, $FO_READ)

		 If $CurrentWorkingFileOpen = -1 Then

			;Set message
			$Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";100;The application was unable to open file "&$CurrentWorkingFile&"."

			;Notify
			consolewrite($Message&@CRLF)

			;Log
			FileWriteLine($LogFile,$Message)

		 EndIf

		 ; Read the contents of the file using the handle returned by FileOpen.
		 Local $CurrentWorkingFileRead = FileRead($CurrentWorkingFileOpen)

		 ;Store the message contents just in case
		 $RawMessageContent	=	$CurrentWorkingFileRead

		 ; Close the handle returned by FileOpen.
		 FileClose($CurrentWorkingFileOpen)

		 ;If the file is empty
		 If StringStripWS($CurrentWorkingFileRead,8) = "" Then

			;Set message
			$Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";1;File "&$CurrentWorkingFile&" is empty."

			;Notify
			consolewrite($Message&@CRLF)

			;Log
			FileWriteLine($LogFile,$Message)

			;Enable Switch
			$FILE_IS_EMPTY = 1

		 Else

			;Replace = with something impossible to exist
			$TempTextString	=	StringReplace($CurrentWorkingFileRead,"=HEADER","{node}HEADER")
			$TempTextString	=	StringReplace($TempTextString,"=PRIORITY","{node}PRIORITY")
			$TempTextString	=	StringReplace($TempTextString,"=DESTINATION TYPE B","{node}DESTINATION TYPE B")
			$TempTextString	=	StringReplace($TempTextString,"=ORIGIN","{node}ORIGIN")
			$TempTextString	=	StringReplace($TempTextString,"=DBLSIG","{node}DBLSIG")
			$TempTextString	=	StringReplace($TempTextString,"=MSGID","{node}MSGID")
			$TempTextString	=	StringReplace($TempTextString,"=SMI","{node}SMI")
			$TempTextString	=	StringReplace($TempTextString,"=TEXT","{node}TEXT")

			;Re declare the file contents
			$CurrentWorkingFileRead	=	$TempTextString

			;Split the string by {}
			$ParentArray	=	StringSplit($CurrentWorkingFileRead,"{node}",1)

			;Declare default values
			$ReceivedDateTime			=	""		;Mandatory	-	Received datetime
			$Originator					=	""		;Mandatory	-	Who sent the message
			$Priority					=	""		;Mandatory	-	The priority of the message
			$DoubleSignature			=	""		;Optional	-	The double signature of the message
			$Identifier					=	"TXF"	;Optional	-	Message Identifier
			Dim $TextArray[1]			=	[0]		;Mandatory	-	The text of the message
			Dim $DestinationsArray[1]	=	[0]		;Mandatory	-	The destinations of the message
			$MessageID					=	""		;Optional  	-	Message ID
			$COR						=	0		;COR Indicator
			$PDM						=	0		;PDM Indicator

			;Loop through parent array elements
			For $j = 1 To $ParentArray[0]

			   ;Split the string by new line
			   $ChildArray = StringSplit($ParentArray[$j],@LF)

			   ;If the array contains some possibly parsable values
			   If $ChildArray[0] >= 2 Then

				  ;If HEADER element was matched
				  If StringStripWS($ChildArray[1],8) 	= "HEADER" Then

					 ;Set received datetime
					 $ReceivedDateTime = StringRegExpReplace(StringReplace(StringRight($ChildArray[2],17),'/','-'), "\r\n|\r|\n", "")

				  ;If PRIORITY element was matched
				  ElseIf StringStripWS($ChildArray[1],8) = "PRIORITY" Then

					 ;If priority is valid
					 If StringLen(StringStripWS($ChildArray[2],8)) = 2 and StringLeft(StringStripWS($ChildArray[2],8),1) = "Q" Then

						;Set priority
						$Priority = StringStripWS($ChildArray[2],8)

					 EndIf

				  ;If DESTINATION TYPE B element was matched
				  ElseIf StringStripWS($ChildArray[1],8) = "DESTINATIONTYPEB" Then

					 ;Loop through elements
					 For $o = 2 To $ChildArray[0]

						;If line not empty
						If StringLeft(StringStripWS($ChildArray[$o],8),4) = "STX," And StringLen(StringStripWS($ChildArray[$o],8)) = 11 Then

						   ;Increase array index
						   $DestinationsArray[0]+=1

						   ;Add the destination to the array
						   _ArrayAdd($DestinationsArray,StringRight(StringStripWS($ChildArray[$o],8),7))

						EndIf

					 Next

				  ;If ORIGIN element was matched
				  ElseIf StringStripWS($ChildArray[1],8) = "ORIGIN" Then

					 ;If originator is valid
					 If StringLen(StringStripWS($ChildArray[2],8)) = 7 Then

						;Set originator
						$Originator = StringStripWS($ChildArray[2],8)

					 EndIf

				  ;If DBLSIG element was matched
				  ElseIf StringStripWS($ChildArray[1],8) = "DBLSIG" Then

					 ;If double signature is valid
					 If StringLen(StringStripWS($ChildArray[2],8)) = 2 Then

						;Set double signature
						$DoubleSignature = StringStripWS($ChildArray[2],8)

					 EndIf

				  ;If MSGID element was matched
				  ElseIf StringStripWS($ChildArray[1],8) = "MSGID" Then

					 $MessageID	=	StringStripWS($ChildArray[2],8)

				  ;If SMI element was matched
				  ElseIf StringStripWS($ChildArray[1],8) = "SMI" Then

					 ;Set the identifier
					 $Identifier	=	StringStripWS($ChildArray[2],8)

				  ;If TEXT element was matched
				  ElseIf StringStripWS($ChildArray[1],8) = "TEXT" Then

					 ;Loop through elements
					 For $o = 2 To $ChildArray[0]

						;Increase the array index
						$TextArray[0]+=1

						;Add the line to the array
						_ArrayAdd($TextArray,$ChildArray[$o])

					 Next

				  EndIf

			   EndIf

			Next

			;If message text is empty
			If StringStripWS(_ArrayToString($TextArray,"",1),8) = "" Then

			   ;Set the file to valid
			   $FILE_IS_VALID	=	0

			   ;Set message
			   $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";1;File "&$CurrentWorkingFile&" has data in =TEXT element."

			   ;Notify
			   consolewrite($Message&@CRLF)

			   ;Log
			   FileWriteLine($LogFile,$Message)


			;If message is valid type b (by checking all mandatory elements)
			ElseIf $Originator <> "" And $Priority <> "" And $TextArray[0] > 0 And $DestinationsArray[0] > 0 And $ReceivedDateTime <> "" Then

			   ;Set the file to valid
			   $FILE_IS_VALID	=	1

			   ;Set message
			   $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";0;File "&$CurrentWorkingFile&" is a valid type b message."

			   ;Notify
			   consolewrite($Message&@CRLF)

			   ;Log
			   FileWriteLine($LogFile,$Message)


			;If message is invalid type b
			Else

			   ;Set the file to valid
			   $FILE_IS_VALID	=	0

			   ;Set message
			   $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";1;File "&$CurrentWorkingFile&" is not valid type b message."

			   ;Notify
			   consolewrite($Message&@CRLF)

			   ;Log
			   FileWriteLine($LogFile,$Message)

			EndIf

		 EndIf

		 ;If the file is not empty and valid
		 If $FILE_IS_EMPTY = 0 AND $FILE_IS_VALID = 1 Then

			;Temp array to store optimized databody
			Dim $TempTextArray[1]	=	[0]

			;Actual Message Start
			$MessageTextStart	=	1

			;Actual Message End
			$MessageTextEnd		=	0

			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;;Find empty lines on top of Message Data Body				;;
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			;Loop through message lines
			For $o = 1 To $TextArray[0]

			   ;If first non blank was matched
			   If StringStripWS($TextArray[$o],8) <> "" Then

				  ;Set the start
				  $MessageTextStart = $o

				  ;Stop the loop
				  ExitLoop

			   EndIf

			Next

			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;;Find empty lines on bottom of Message Data Body			;;
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			;Reverse the array
			_ArrayReverse ( $TextArray , 1 , $TextArray[0])

			;Loop through message lines
			For $o = 1 To $TextArray[0]

			   ;If first non blank was matched
			   If StringStripWS($TextArray[$o],8) = "" Then

				  ;Set the end
				  $MessageTextEnd+=1

			   Else

				  ;Stop the loop
				  ExitLoop

			   EndIf

			Next

			;Set the message End
			$MessageTextEnd = $TextArray[0] - $MessageTextEnd

			;Reverse the array
			_ArrayReverse ( $TextArray , 1 , $TextArray[0])

			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;;Reconstruct the data body by removing blank lines			;;
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			;Loop from start to end
			For $o = $MessageTextStart To $MessageTextEnd

			   ;Add to temp array
			   _ArrayAdd($TempTextArray,$TextArray[$o])

			   ;Increase array index
			   $TempTextArray[0]+=1

			Next

			;Re declare the text array
			$TextArray	=	$TempTextArray

			;If a message identifier was found
			If StringStripWS($Identifier,8) <> "" And StringStripWS($Identifier,8) <> "TXF" Then

			   ;Add the identifier to the text array
			   _ArrayInsert($TextArray,1,$Identifier)

			   ;Increase the array index
			   $TextArray[0]+=1

			EndIf

			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;;SMART Parser functionality (Remove MBH)   				   ;;
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			;Set the message data body
			Dim $MessageDataBody[1] = [0]

			If $SmartParser = 1 And Ubound($TextArray) > 1 Then

			   ;If MBH
			   If $TextArray[1] = "MBH" Then

				  ;Declare HBM line position
				  $HBMposition = 1

				  ;Loop through message	 lines
				  For $o = 1 To $TextArray[0]

					 ;If first non blank was matched
					 If StringStripWS($TextArray[$o],8) = "HBM" Then

						;Set the end
						$HBMposition = $o + 1

						;Stop the loop
						ExitLoop

					 EndIf

				  Next

				  ;If HBM was found
				  If $HBMPosition > 0 Then

					 ;Loop and fill the message databody
					 For $o = $HBMPosition To $TextArray[0]

						;Fill
						_ArrayAdd($MessageDataBody, $TextArray[$o])

						;Increase Index
						$MessageDataBody[0]+=1

					 Next

				  Else

					 $MessageDataBody = $TextArray

				  EndIf

			   Else

				  $MessageDataBody = $TextArray

			   EndIf

			   $MessageDataBodyStart = 1

			   Dim $TempArray[1]	=	[0]

			   ;Loop to remove ATTN,FROM,TO,SUBJ
			   For $o = $MessageDataBodyStart To $MessageDataBody[0]

				  If StringLeft(StringStripWS($MessageDataBody[$o],8),4) = "ATTN" Then


				  ElseIf StringLeft(StringStripWS($MessageDataBody[$o],8),4) = "SUBJ" Then

				  ElseIf StringLeft(StringStripWS($MessageDataBody[$o],8),4) = "FROM" Then

				  ElseIf StringLeft(StringStripWS($MessageDataBody[$o],8),3) = "TO:" Then

				  ElseIf StringLeft(StringStripWS($MessageDataBody[$o],8),3) = "" Then

				  Else

					 _ArrayAdd($TempArray,$MessageDataBody[$o])

					 $TempArray[0]+=1

				  EndIf

			   Next

			   If $TempArray[0] > 0 Then

				  $MessageDataBody = $TempArray

			   EndIf

			Else

			   ;Set the message data body
			   $MessageDataBody = $TextArray

			EndIf

			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;;Find PDM													;;
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			;Redeclare message text start
			$MessageDataBodyStart = 1

			$MessageDataBodyEnd	  = $MessageDataBody[0]

			;If PDM
			If $MessageDataBodyStart > 1 And StringStripWS($MessageDataBody[$MessageDataBodyStart],8) = "PDM" Then

			   ;Set PDM to on
			   $PDM	=	1

			   ;Increase message text start
			   $MessageDataBodyStart+=1

			EndIf

			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;;Find COR													;;
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			;If COR
			If $MessageDataBodyStart > 1 And StringStripWS($MessageDataBody[$MessageDataBodyStart],8) = "COR" Then

			   ;Set PDM to on
			   $COR	=	1

			   ;Increase message text start
			   $MessageDataBodyStart+=1

			EndIf

			Dim $TempArray[1] = [0]

			;Reconstruct data body
			For $o = $MessageDataBodyStart To $MessageDataBodyEnd

			   _ArrayAdd($TempArray,$MessageDataBody[$o])

			   $TempArray[0]+=1

			Next

			$MessageDataBody	=	$TempArray

			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;;Check identifier filtering								;;
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			;Search if message identifier is accepted
			$IdentifierIndex = _ArraySearch($AllowedIdentifiersArray, StringLeft(StringStripWS($MessageDataBody[1],8),3), 1)

			;A boolean switch to handle message to email transmission switch
			$MessageIsMatched	=	0

			;If accepted
			If $IdentifierIndex > 0 or $AllowAllIdentifiers = 1 Then

			   ;Update the switch
			   $MessageIsMatched	=	1
			   $MessageIsMatchedLog	=	"Identifier matches system configuration."

			;If not accepted
			Else

			   ;Update the switch
			   $MessageIsMatched	=	0
			   $MessageIsMatchedLog	=	"Identifier does not match system configuration."

			EndIf

			;Declare a string for writing message text in the log
			$TextStringForLog = ""

			;Loop through text
			For $o = 1 To $TextArray[0]

			   If $o = 1 Then

				  $TextStringForLog &= "["&StringFormat("%03s",$o)&"] -> "&$TextArray[$o]&@LF

			   Else

				  $TextStringForLog &= "                                        ["&StringFormat("%03s",$o)&"] -> "&$TextArray[$o]&@LF

			   EndIf

			Next

			;Set message
			$Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";0;File "&$CurrentWorkingFile&" parsed. Data were the following:" &@CRLF& _
					   "                    Received On      -> "&$ReceivedDateTime&@CRLF& _
					   "                    COR Indicator    -> "&$COR&@CRLF& _
					   "                    PDM Indicator    -> "&$PDM&@CRLF& _
					   "                    Originator       -> "&$Originator&@CRLF& _
					   "                    Destination(s)   -> "&_ArrayToString($DestinationsArray,', ', 1)&@CRLF& _
					   "                    Message ID       -> "&$MessageID&@CRLF& _
					   "                    Double Signature -> "&$DoubleSignature&@CRLF& _
					   "                    Priority         -> "&$Priority&@CRLF& _
					   "                    Identifier       -> "&$MessageDataBody[1]&@CRLF& _
					   "                    Message Matched  -> "&$MessageIsMatchedLog&@CRLF& _
					   "                    Text             -> "&$TextStringForLog

			;Notify
			consolewrite($Message&@CRLF)

			;Log
			FileWriteLine($LogFile,$Message)

			;If message was not matched
			If $MessageIsMatched = 0 Then

			   ;Declare the dynamic unparsed path
			   $DynamicUnparsedPath	=	$UnparsedPath&'\'&_WM_Date_Generate_UTC_DateTime("YEAR")&'\'&_WM_Date_Generate_UTC_DateTime("MON")&'\'&_WM_Date_Generate_UTC_DateTime("DAY")

			   ;Set message
			   $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";0;Attemtping to move file "&$CurrentWorkingFile&" to directory "&$DynamicUnparsedPath&"."

			   ;Notify
			   consolewrite($Message&@CRLF)

			   ;Log
			   FileWriteLine($LogFile,$Message)

			   ;If unable to move to unparsed
			   If Not FileMove($CurrentWorkingFile, $DynamicUnparsedPath&'\'&$CurrentWorkingFileName, $FC_OVERWRITE + $FC_CREATEPATH) Then

				  ;Set message
				  $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";100;The application was unable to move file "&$CurrentWorkingFile&" to directory "&$DynamicUnparsedPath&"."

				  ;Notify
				  consolewrite($Message&@CRLF)

				  ;Log
				  FileWriteLine($LogFile,$Message)

			   ;If able to move to unparsed
			   Else

				  ;Set message
				  $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";0;File "&$CurrentWorkingFile&" moved to directory "&$DynamicUnparsedPath&"."

				  ;Notify
				  consolewrite($Message&@CRLF)

				  ;Log
				  FileWriteLine($LogFile,$Message)

			   EndIf

			;If message was matched
			Else

			   ;Declare the email body
			   $EmailBody = $RawMessageContent

			   ;Generate the email subject
			   $temp = StringReplace($ReceivedDateTime,":","")
			   $temp = StringReplace($temp,"-","")
			   $temp = StringReplace($temp," ","")

			   $EmailSubject = $MessageDataBody[1]&" "&$temp

				;Set message
				$Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";0;Starting email transmission."

				;Notify
				consolewrite($Message&@CRLF)

				;Log
				FileWriteLine($LogFile,$Message)

			   ;john.papagiannoulis@gmail.com
			   _INetSmtpMailCom($MailServer, $MailFromName, $MailFromAddress, $MailDestination, $EmailSubject, $EmailBody, "", $MailCCDestination, $MailBCCDestination, $MailImportance, $MailUsername, $MailPassword, $MailPort , $MailSSL)

				If @error Then

						;Set message
						$Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";200;Unable to send email message. Error details are the following:"&@CRLF& _
						           "                                              Error code        -> "&@error&" returned from _INetSmtpMailCom."&@CRLF& _
								   "                                              Error description -> "&$oMyRet[1]&@CRLF& _
								   "                                              Hex code          -> "&$oMyRet[0]&@CRLF
						;Notify
						consolewrite($Message&@CRLF)

						;Log
						FileWriteLine($LogFile,$Message)

				Else

					;Set message
					$Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";0;Email message sent successfully."&@CRLF

					;Notify
					consolewrite($Message)

					;Log
					FileWriteLine($LogFile,$Message)

					;Declare the dynamic parsed path
					$DynamicParsedPath	=	$ParsedPath&'\'&_WM_Date_Generate_UTC_DateTime("YEAR")&'\'&_WM_Date_Generate_UTC_DateTime("MON")&'\'&_WM_Date_Generate_UTC_DateTime("DAY")

					;Set message
					$Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";0;Attemtping to move file "&$CurrentWorkingFile&" to directory "&$DynamicParsedPath&"."

					;Notify
					consolewrite($Message&@CRLF)

					;Log
					FileWriteLine($LogFile,$Message)

					;If unable to move to unparsed
					If Not FileMove($CurrentWorkingFile, $DynamicParsedPath&'\'&$CurrentWorkingFileName, $FC_OVERWRITE + $FC_CREATEPATH) Then

					   ;Set message
					   $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";100;The application was unable to move file "&$CurrentWorkingFile&" to directory "&$DynamicParsedPath&"."

					   ;Notify
					   consolewrite($Message&@CRLF)

					   ;Log
					   FileWriteLine($LogFile,$Message)

					;If able to move to unparsed
					Else

					   ;Set message
					   $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";0;File "&$CurrentWorkingFile&" moved to directory "&$DynamicParsedPath&"."

					   ;Notify
					   consolewrite($Message&@CRLF)

					   ;Log
					   FileWriteLine($LogFile,$Message)

					EndIf

			    EndIf

			EndIf

		 ;If the file is not empty but not valid or if the file is empty
		 ElseIf ($FILE_IS_EMPTY = 0 AND $FILE_IS_VALID = 0) OR $FILE_IS_EMPTY = 1 Then

			;Declare the dynamic unparsed path
			$DynamicUnparsedPath	=	$UnparsedPath&'\'&_WM_Date_Generate_UTC_DateTime("YEAR")&'\'&_WM_Date_Generate_UTC_DateTime("MON")&'\'&_WM_Date_Generate_UTC_DateTime("DAY")

			;Set message
			$Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";0;Attemtping to move file "&$CurrentWorkingFile&" to directory "&$DynamicUnparsedPath&"."

			;Notify
			consolewrite($Message&@CRLF)

			;Log
			FileWriteLine($LogFile,$Message)

			;If unable to move to unparsed
			If Not FileMove($CurrentWorkingFile, $DynamicUnparsedPath&'\'&$CurrentWorkingFileName, $FC_OVERWRITE + $FC_CREATEPATH) Then

			   ;Set message
			   $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";100;The application was unable to move file "&$CurrentWorkingFile&" to directory "&$DynamicUnparsedPath&"."

			   ;Notify
			   consolewrite($Message&@CRLF)

			   ;Log
			   FileWriteLine($LogFile,$Message)

			;If able to move to unparsed
			Else

			   ;Set message
			   $Message = _WM_Date_Generate_UTC_DateTime("DT")&";"&@ScriptName&";0;File "&$CurrentWorkingFile&" moved to directory "&$DynamicUnparsedPath&"."

			   ;Notify
			   consolewrite($Message&@CRLF)

			   ;Log
			   FileWriteLine($LogFile,$Message)

			EndIf

		 ;If something else happened
		 Else

		 EndIf


	  Next
	  exit

   EndIf