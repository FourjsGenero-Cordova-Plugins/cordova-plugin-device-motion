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

IMPORT FGL fglcdvMotion

TYPE EvinfoT RECORD
    timestamp DATETIME YEAR TO FRACTION(3),
    data STRING
END RECORD

MAIN
    DEFINE s INTEGER
    DEFINE evarr DYNAMIC ARRAY OF EvinfoT

    OPEN FORM f FROM "main"
    DISPLAY FORM f

    CALL fglcdvMotion.initialize()

    MENU "Accelerometer"
    BEFORE MENU
        CALL setup_dialog(DIALOG)
    ON ACTION start
        IF fglcdvMotion.start() == 0 THEN
            MESSAGE "Accelerometer data gathering started"
        ELSE
            ERROR "Could not start collecting accelerometer data"
        END IF
        CALL setup_dialog(DIALOG)
    ON ACTION stop
        IF fglcdvMotion.stop() == 0 THEN
            MESSAGE "Accelerometer data gathering stopped"
        ELSE
            ERROR "Failed to start collecting accelerometer data"
        END IF
        CALL setup_dialog(DIALOG)
    ON IDLE 1
        IF fglcdvMotion.isStarted() THEN
            LET s = collectEvents(evarr)
            IF s >= 0 THEN
                DISPLAY evarr.getLength() TO event_count
                DISPLAY fglcdvMotion.getFetchTime() TO fetch_time
            ELSE
                ERROR "Could not fetch motion events."
            END IF
        END IF
    ON ACTION show
        CALL showBackgroundEvents(evarr)
        CALL setup_dialog(DIALOG)
    ON ACTION quit
        EXIT MENU
    END MENU

    CALL fglcdvMotion.finalize()

END MAIN

FUNCTION setup_dialog(d ui.Dialog)
    CALL d.setActionActive("start", NOT isStarted())
    CALL d.setActionActive("stop", isStarted())
    CALL d.setActionActive("show", NOT isStarted())
END FUNCTION

FUNCTION collectEvents(evarr DYNAMIC ARRAY OF EvinfoT)
    DEFINE mda fglcdvMotion.MotionDataArrayT
    DEFINE c, i, n INTEGER
    LET c = fglcdvMotion.getNextData(mda)
    IF c < 0 THEN RETURN c END IF
    FOR i=1 TO c
        LET n = evarr.getLength()+1
        LET evarr[n].timestamp = util.Datetime.fromSecondsSinceEpoch( mda[i].timestamp / 1000 )
        LET evarr[n].data = SFMT("x=%1, y=%2, z=%3",
                                 mda[i].x, mda[i].y, mda[i].z)
    END FOR
    RETURN c
END FUNCTION

FUNCTION showBackgroundEvents(evarr DYNAMIC ARRAY OF EvinfoT)
    DEFINE result STRING
    OPEN WINDOW w1 WITH FORM "bgevents"
    DISPLAY ARRAY evarr TO scr.* ATTRIBUTE(UNBUFFERED,ACCEPT=FALSE)
    ON ACTION clear ATTRIBUTE(TEXT="Clear")
       CALL evarr.clear()
       MESSAGE "Events cleared."
  END DISPLAY
  CLOSE WINDOW w1
END FUNCTION
