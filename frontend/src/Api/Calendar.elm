module Api.Calendar
    exposing
        ( CalendarsStatus(..)
        , Calendar
        , Calendars
        , Meeting
        , empty
        , disconnect
        , fetchAll
        , refresh
        , createMeeting
        , fetchMeetings
        , fetchMeeting
        , setDefaultCalendar
        )

import Api exposing (Errors, Error, Response, getJson, patchJson, postJson, postPlain)
import Json.Decode as Json exposing (Decoder, (:=), string, maybe, list)
import Json.Encode as JE
import Task exposing (Task)
import Timestamp exposing (Timestamp, Timezone, isoFormat)
import Util exposing ((=>))


type alias Calendar =
    { id : String
    , summary : Maybe String
    , timezone : Maybe Timezone
    }


type alias Calendars =
    { status : CalendarsStatus
    , defaultId : String
    , calendars : List Calendar
    }


type alias Meeting =
    { id : String
    , startTime : Timestamp
    , endTime : Timestamp
    , summary : String
    , description : String
    , attendees : List String
    }


type CalendarsStatus
    = Loading
    | Done


empty : Calendars
empty =
    { status = Loading
    , defaultId = ""
    , calendars = []
    }


calendar : Decoder Calendar
calendar =
    Json.object3 Calendar
        ("id" := string)
        ("summary" := maybe string)
        ("timezone" := maybe string)


calendarStatus : Decoder CalendarsStatus
calendarStatus =
    let
        convert s =
            if s == "done" then
                Done
            else
                Loading
    in
        string `Json.andThen` (Json.succeed << convert)


calendars : Decoder Calendars
calendars =
    Json.object3 Calendars
        ("status" := calendarStatus)
        ("defaultId" := string)
        ("calendars" := list calendar)


integrationPayload : JE.Value
integrationPayload =
    JE.object [ "integration" => JE.string "gcalendar" ]


disconnect : Task Error (Response String)
disconnect =
    postPlain integrationPayload "integrations/disconnect"


fetchAll : Task Error (Response Calendars)
fetchAll =
    getJson calendars "integrations/gcalendar/data"


refresh : Task Error (Response String)
refresh =
    postPlain integrationPayload "integrations/refresh"


encodeMeeting : Meeting -> JE.Value
encodeMeeting meeting =
    JE.object
        [ "startTime" => JE.string (isoFormat meeting.startTime)
        , "endTime" => JE.string (isoFormat meeting.endTime)
        , "summary" => JE.string meeting.summary
        , "description" => JE.string meeting.description
        , "attendees" => JE.list (List.map JE.string meeting.attendees)
        ]


createMeeting : Meeting -> Task Error (Response Meeting)
createMeeting m =
    postJson (encodeMeeting m) meeting "integrations/gcalendar/meetings"


timestamp : Decoder Timestamp
timestamp =
    Json.map Timestamp.fromString Json.string


meeting : Decoder Meeting
meeting =
    Json.object6 Meeting
        ("id" := Json.string)
        ("startTime" := timestamp)
        ("endTime" := timestamp)
        ("summary" := Json.string)
        ("description" := Json.string)
        ("attendees" := Json.list Json.string)


meetings : Decoder (List Meeting)
meetings =
    Json.oneOf
        [ Json.list meeting
        , Json.succeed []
        ]


fetchMeetings : Task Error (Response (List Meeting))
fetchMeetings =
    getJson meetings "integrations/gcalendar/meetings"


fetchMeeting : String -> Task Error (Response Meeting)
fetchMeeting id =
    getJson meeting ("integrations/gcalendar/meetings/" ++ id)


setDefaultCalendar : String -> Task Error (Response Calendars)
setDefaultCalendar id =
    patchJson (JE.object [ "calendarId" => JE.string id ]) calendars "integrations/gcalendar/meetings"
