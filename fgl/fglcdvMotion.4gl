#
#       (c) Copyright Four Js 2017.
#
#                                 Apache License
#                           Version 2.0, January 2004
#
#       https://www.apache.org/licenses/LICENSE-2.0

#+ Genero BDL wrapper around the Cordova Accelerometer plugin.
#+
#+ For device motion capture, we cannot use the cordovacallback action, because
#+ it would generate too much traffic (the app would not respond anymore).
#+ Instead, we use async Cordova calls and fetch the data with callback methods.
#+

IMPORT util

#+ The MotionDataT type contains motion capture data.
#+
#+ The MotionDataT structure contains accelerometer data captured at a specific
#+ point in time.
#+
#+ Acceleration values include the effect of gravity (9.81 m/s^2), so that when
#+ a device lies flat and facing up, x, y, and z values returned should be 0,
#+ 0, and 9.81.
#+
#+ The timestamp member is a FLOAT representing the number of milliseconds
#+ since epoch (1970-01-01). Such value can be converted to a DATETIME with
#+ the timestampMillisecondsToDatetime() function.
#+
#+ Record members are:
#+
#+  x FLOAT : Amount of acceleration on the x-axis (in m/s^2)
#+
#+  y FLOAT : Amount of acceleration on the y-axis (in m/s^2)
#+
#+  z FLOAT : Amount of acceleration on the z-axis (in m/s^2)
#+
#+  timestamp FLOAT : Motion data record creation timestamp in milliseconds
#+
PUBLIC TYPE MotionDataT RECORD
    x FLOAT,
    y FLOAT,
    z FLOAT,
    timestamp FLOAT
END RECORD

#+ The MotionDataArrayT type defins a dynamic array of motion data records.
#+
#+ This type is used by the getNextData() function to return motion data.
#+
PUBLIC TYPE MotionDataArrayT DYNAMIC ARRAY OF MotionDataT

PRIVATE DEFINE callbackIdStart STRING
PRIVATE DEFINE callbackIdStop STRING
PRIVATE DEFINE fetchTime INTERVAL SECOND TO FRACTION(3)

PRIVATE DEFINE initialized BOOLEAN

#+ Initializes the plugin library
#+
#+ The init() function must be called prior to other calls.
#+
PUBLIC FUNCTION init()
    IF initialized THEN -- exclusive library usage
        CALL fatalError("The library is already in use.")
    END IF
    -- do init stuff
    LET initialized = TRUE
END FUNCTION

#+ Finalizes the plugin library
#+
#+ The fini() function should be called when the library is no longer used.
#+
PUBLIC FUNCTION fini()
    IF initialized THEN
        -- do fini stuff
        LET initialized = FALSE
    END IF
END FUNCTION

PRIVATE FUNCTION fatalError(msg STRING)
    DISPLAY "fglcdvMotion error: ", msg
    EXIT PROGRAM 1
END FUNCTION

PRIVATE FUNCTION check_lib_state()
    IF NOT initialized THEN
        CALL fatalError("Library is not initialized.")
    END IF
END FUNCTION

#+ Start to capture motion data.
#+
#+ This function starts to collect accelerometer motion data.
#+ Once started, it is possible to fetch the motion data with getNextData(),
#+ or stop the capture with stop().
#+
#+ @return 0 upon success, -1 in case of error
PUBLIC FUNCTION start() RETURNS INTEGER
    CALL check_lib_state()
    IF callbackIdStart IS NOT NULL THEN
        RETURN -2
    END IF
    TRY
        CALL ui.interface.frontcall("cordova","callWithoutWaiting",
                ["Accelerometer","start"], [callbackIdStart])
    CATCH
        RETURN -1
    END TRY
    RETURN 0
END FUNCTION

#+ Stop capture of motion data.
#+
#+ This function stops collecting accelerometer motion data.
#+ After the stop, it is possible to fetch the motion data with getNextData(),
#+ or restart the capture with start().
#+
#+ @return 0 upon success, -1 in case of error
PUBLIC FUNCTION stop() RETURNS INTEGER
    DEFINE tmp STRING
    CALL check_lib_state()
    IF callbackIdStart IS NULL THEN
        RETURN -2
    END IF
    TRY
        CALL ui.interface.frontcall("cordova","callWithoutWaiting",
                ["Accelerometer","stop"], [callbackIdStop])
        --empty the native side
        CALL ui.interface.frontcall("cordova","getAllCallbackData",
                [callbackIdStop], [tmp])
        LET callbackIdStart=NULL
    CATCH
        RETURN -1
    END TRY
    RETURN 0
END FUNCTION

#+ Returns TRUE if the motion capture has started.
#+
#+ @return TRUE if motion capture is started.
PUBLIC FUNCTION isStarted() RETURNS BOOLEAN
    CALL check_lib_state()
    RETURN ( callbackIdStart IS NOT NULL )
END FUNCTION

#+ Fetches next motion data records.
#+
#+ Use this function to retrieve motion data records into the dynamic array
#+ passed as parameter.
#+
#+ The function returns the number of records found or -1 in case of error.
#+
#+ You typically want to call this function in regular intervals, once the
#+ motion capture is started, for example in on ON IDLE trigger.
#+
#+ @param mda - is the dynamic array of motion data records to fill.
#+
#+ @code
#+ DEFINE mda fglcdvMotion.MotionDataArrayT,
#+        i, cnt INTEGER
#+ LET cnt = fglcdvMotion.getNextData( mda )
#+ FOR i=1 TO cnt
#+     DISPLAY mda[x].*
#+ END FOR
#+
#+ @return -1 if error, >=0 the number of motion data records fetched.
PUBLIC FUNCTION getNextData(mda MotionDataArrayT) RETURNS INTEGER
    DEFINE ts DATETIME HOUR TO FRACTION(3)
    CALL check_lib_state()
    LET ts = CURRENT
    LET fetchTime = NULL
    CALL mda.clear()
    TRY
        CALL ui.interface.frontcall("cordova","getAllCallbackData",
                [callbackIdStart], [mda])
        LET fetchTime = CURRENT - ts
    CATCH
        RETURN -1
    END TRY
    RETURN mda.getLength()
END FUNCTION

#+ Returns the time it took to fetch motion data with getNextData().
#+
#+ @return the fetch time.
PUBLIC FUNCTION getFetchTime()
                   RETURNS INTERVAL SECOND TO FRACTION(3)
    CALL check_lib_state()
    RETURN fetchTime
END FUNCTION

#+ Converts a number of milliseconds since epoch to a DATETIME.
#+
#+ This helper function is provided to convert the timestamp member of
#+ a MotionDataT record to a regular BDL DATETIME YEAR TO FRACTION(3).
#+
#+ @param ms - the number of milliseconds since epoch (1970-01-01).
#+
#+ @return the resulting DATETIME value.
PUBLIC FUNCTION timestampMillisecondsToDatetime( ms FLOAT )
                   RETURNS DATETIME YEAR TO FRACTION(3)
    DEFINE s FLOAT
    DEFINE dt DATETIME YEAR TO FRACTION(3)
    LET s = ms / 1000
    LET dt = util.Datetime.fromSecondsSinceEpoch( s )
    RETURN dt
END FUNCTION
