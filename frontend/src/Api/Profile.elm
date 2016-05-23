module Api.Profile
    exposing
        ( Profile
        , createUploadUri
        , deleteAvatar
        , updateProfile
        )

import Api exposing (Errors, Error, Response, deletePlain, getJson, postPlain)
import Json.Decode as Json exposing (Decoder, (:=), string)
import Json.Encode
import Task exposing (Task)
import Types exposing (Workdays, Workday)
import Util exposing ((=>))


type alias Profile =
    { firstName : String
    , lastName : String
    , timezone : String
    , workdays : Workdays
    }


createUploadUri : Task Error (Response String)
createUploadUri =
    getJson ("uri" := string) "upload"


deleteAvatar : Task Error (Response String)
deleteAvatar =
    deletePlain "avatar"


updateProfile : Profile -> Task Error (Response String)
updateProfile profile =
    postPlain (encodeProfile profile) "profile"


encodeWorkday : Workday -> Json.Encode.Value
encodeWorkday workday =
    Json.Encode.object
        [ "start" => Json.Encode.int workday.start
        , "end" => Json.Encode.int workday.end
        ]


encodeWorkdays : Workdays -> Json.Encode.Value
encodeWorkdays workdays =
    Json.Encode.object
        [ "monday" => encodeWorkday workdays.monday
        , "tuesday" => encodeWorkday workdays.tuesday
        , "wednesday" => encodeWorkday workdays.wednesday
        , "thursday" => encodeWorkday workdays.thursday
        , "friday" => encodeWorkday workdays.friday
        , "saturday" => encodeWorkday workdays.saturday
        , "sunday" => encodeWorkday workdays.sunday
        ]


encodeProfile : Profile -> Json.Encode.Value
encodeProfile profile =
    Json.Encode.object
        [ "firstName" => Json.Encode.string profile.firstName
        , "lastName" => Json.Encode.string profile.lastName
        , "timezone" => Json.Encode.string profile.timezone
        , "workdays" => encodeWorkdays profile.workdays
        ]
