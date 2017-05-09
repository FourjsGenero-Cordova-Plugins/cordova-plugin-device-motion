# Property of Four Js*
# (c) Copyright Four Js 2017, 2017. All Rights Reserved.
# * Trademark of Four Js Development Tools Europe Ltd
#   in the United States and elsewhere
# 
# Four Js and its suppliers do not warrant or guarantee that these
# samples are accurate and suitable for your purposes. Their inclusion is
# purely for information purposes only.

#+ Cordova Accelerometer plugin demo 
IMPORT util
IMPORT os
IMPORT FGL fgldialog
DEFINE bgEvents DYNAMIC ARRAY OF RECORD
  timestamp FLOAT,
  callbackId STRING,
  x FLOAT,
  y FLOAT,
  z FLOAT
END RECORD

DEFINE allEvents DYNAMIC ARRAY OF RECORD
  x FLOAT,
  y FLOAT,
  z FLOAT,
  timestamp DECIMAL
END RECORD

MAIN
    DEFINE callbackId,callbackIdStop STRING
    OPEN FORM f FROM "main"
    DISPLAY FORM f
    MENU "Accelerometer"
    ON ACTION start 
      CALL ui.interface.frontcall("cordova","callWithoutWaiting",
        ["Accelerometer","start"],[callbackId])
      MESSAGE callbackId
    ON ACTION stop 
      --we need to use the async call here because no result is returned on IOS
      CALL ui.interface.frontcall("cordova","callWithoutWaiting",
        ["Accelerometer","stop"],[callbackIdStop])
      CALL getEvents(callbackId,callbackIdStop) --empty the native side
      LET callbackId=NULL
    --we do not use the cordovacallback action here because it generates too much traffic (the app will be not responsive anymore)
    --instead we fetch the data in chunks each second
    ON IDLE 1
       IF callbackId IS NOT NULL THEN
         CALL getEvents(callbackId,callbackIdStop)
       END IF
    ON ACTION show ATTRIBUTES(TEXT="Show Background events",COMMENT="Shows the list of accelerometer events")
       CALL showBgEvents()
       DISPLAY bgEvents.getLength() TO eventCount
    END MENU
END MAIN

FUNCTION getEvents(callbackId,callbackIdStop)
   DEFINE callbackId,callbackIdStop,results STRING
   DEFINE i, idx INT
   DEFINE starttime DATETIME HOUR TO FRACTION(2)
   DEFINE diff INTERVAL SECOND TO FRACTION(2)
   LET starttime=CURRENT
   CALL ui.interface.frontcall("cordova","getallcallbackdata",[callbackId],[allEvents])
   FOR i=1 TO allEvents.getLength()
         LET idx=bgEvents.getLength()+1
         LET bgEvents[idx].timestamp=allEvents[i].timestamp
         LET bgEvents[idx].callbackId=callbackId
         LET bgEvents[idx].x=allEvents[i].x
         LET bgEvents[idx].y=allEvents[i].y
         LET bgEvents[idx].z=allEvents[i].z
    END FOR
    IF allEvents.getLength()>0 THEN
      DISPLAY idx TO eventCount
      LET diff=CURRENT-starttime
      DISPLAY diff TO t --just a trace to know how long the operation did take
    END IF 
    --clear possible stop events (Android)
    IF callbackIdStop IS NOT NULL THEN
      CALL ui.interface.frontcall("cordova","getallcallbackdata",[callbackIdStop],[results])
    END IF
END FUNCTION

FUNCTION showBgEvents()
  DEFINE result STRING
  OPEN WINDOW bgEvents WITH FORM "bgevents"
  DISPLAY ARRAY bgEvents TO scr.* ATTRIBUTE(UNBUFFERED,ACCEPT=FALSE,DOUBLECLICK=select)
     ON ACTION select 
       OPEN WINDOW detail WITH FORM "detail"
       DISPLAY BY NAME bgEvents[arr_curr()].*
       MENU 
         ON ACTION close
           EXIT MENU
       END MENU
       CLOSE WINDOW detail
     ON ACTION clear ATTRIBUTE(TEXT="Clear")
       CALL bgEvents.clear()
       MESSAGE "Events cleared"
  END DISPLAY
  CLOSE WINDOW bgEvents
END FUNCTION
