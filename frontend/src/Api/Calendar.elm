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
        )

import Api exposing (Errors, Error, Response, getJson, postJson, postPlain)
import Json.Decode as Json exposing (Decoder, (:=), string, maybe, list)
import Json.Encode
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
    { startTime : Timestamp
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


integrationPayload : Json.Encode.Value
integrationPayload =
    Json.Encode.object [ "integration" => Json.Encode.string "gcalendar" ]


disconnect : Task Error (Response String)
disconnect =
    postPlain integrationPayload "integrations/disconnect"


fetchAll : Task Error (Response Calendars)
fetchAll =
    getJson calendars "integrations/gcalendar/data"


refresh : Task Error (Response String)
refresh =
    postPlain integrationPayload "integrations/refresh"


encodeMeeting : Meeting -> Json.Encode.Value
encodeMeeting meeting =
    Json.Encode.object
        [ "startTime" => Json.Encode.string (isoFormat meeting.startTime)
        , "endTime" => Json.Encode.string (isoFormat meeting.endTime)
        , "summary" => Json.Encode.string meeting.summary
        , "description" => Json.Encode.string meeting.description
        , "attendees" => Json.Encode.list (List.map Json.Encode.string meeting.attendees)
        ]


createMeeting : Meeting -> Task Error (Response String)
createMeeting =
    encodeMeeting >> flip postPlain "integrations/gcalendar/meetings"


meeting : Decoder Meeting
meeting =
    Json.object5 Meeting
        ("startTime" := Json.float)
        ("endTime" := Json.float)
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
