#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.10.2
 Author:         George Roubis

 Script Function:
	Generates UTC datetime

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
	Func _WM_Date_Generate_UTC_DateTime($MODE)

		;Get local datetime
		$tLocal = _Date_Time_GetLocalTime()

		;Convert local datetime to UTC
		$tSystem = _Date_Time_TzSpecificLocalTimeToSystemTime(DllStructGetPtr($tLocal))

		;Get the initial output string
		$tSystem_String = _Date_Time_SystemTimeToDateTimeStr($tSystem)

		;Get output day
		$O_MDAY = 	StringMid($tSystem_String,4,2)

		;Get output month
		$O_MON	=	StringMid($tSystem_String,1,2)

		;Get output year
		$O_YEAR =	StringMid($tSystem_String,7,4)

		;Get output hour
		$O_HOUR = 	StringMid($tSystem_String,12,2)

		;Get output minutes
		$O_MIN	=	StringMid($tSystem_String,15,2)

		;Get output seconds
		$O_SEC =	StringMid($tSystem_String,18,2)

	  If $MODE = "DT" Then

		 ;Generate output
		 $Output = $O_YEAR&'-'&$O_MON&'-'&$O_MDAY&' '&$O_HOUR&':'&$O_MIN&':'&$O_SEC

	  ElseIf $MODE = "YEAR" Then

		 ;Generate output
		 $Output	=	$O_YEAR

	  ElseIf $MODE = "MON" Then

		 ;Generate output
		 $Output	=	$O_MON

	  ElseIf $MODE = "DAY" Then

		 ;Generate output
		 $Output	=	$O_MDAY

	  EndIf

		;Return the output
		Return $Output

	EndFunc
