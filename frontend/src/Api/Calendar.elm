module Api.Calendar
    exposing
        ( CalendarsStatus(..)
        , Calendar
        , Calendars
        , empty
        , disconnect
        , fetchAll
        , refresh
        )

import Api exposing (Errors, Error, Response, getJson, postJson, postPlain)
import Json.Decode as Json exposing (Decoder, (:=), string, maybe, list)
import Json.Encode
import Task exposing (Task)
import Timestamp exposing (Timezone)
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
